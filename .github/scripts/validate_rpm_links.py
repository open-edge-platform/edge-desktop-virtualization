#!/usr/bin/env python3

import argparse
import hashlib
import html.parser
import pathlib
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple


BASEOS_URL = "http://mirror.stream.centos.org/9-stream/BaseOS/x86_64/os/Packages/"
APPSTREAM_URL = "http://mirror.stream.centos.org/9-stream/AppStream/x86_64/os/Packages/"
BUILDDEPS_PREFIX = "https://storage.googleapis.com/builddeps/"


@dataclass
class RpmBlock:
    start: int
    end: int
    text: str
    name: str
    sha256: str
    urls: List[str]


class LinkIndexParser(html.parser.HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.links: List[str] = []

    def handle_starttag(self, tag: str, attrs: List[Tuple[str, Optional[str]]]) -> None:
        if tag.lower() != "a":
            return
        attr_map = dict(attrs)
        href = attr_map.get("href")
        if href:
            self.links.append(href)


def is_url_alive(url: str, timeout: int = 20) -> bool:
    req = urllib.request.Request(url, method="HEAD")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return 200 <= resp.status < 400
    except Exception:
        pass

    req = urllib.request.Request(url, method="GET")
    req.add_header("Range", "bytes=0-0")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return 200 <= resp.status < 400
    except Exception:
        return False


def fetch_html(url: str, timeout: int = 30) -> str:
    with urllib.request.urlopen(url, timeout=timeout) as resp:
        return resp.read().decode("utf-8", errors="replace")


def fetch_sha256(url: str, timeout: int = 60) -> str:
    h = hashlib.sha256()
    with urllib.request.urlopen(url, timeout=timeout) as resp:
        while True:
            chunk = resp.read(1024 * 1024)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def natural_key(value: str) -> List[object]:
    parts = re.split(r"(\d+)", value)
    key: List[object] = []
    for part in parts:
        if part.isdigit():
            key.append(int(part))
        else:
            key.append(part)
    return key


def parse_rpm_blocks(content: str) -> List[RpmBlock]:
    blocks: List[RpmBlock] = []
    i = 0
    while True:
        start = content.find("rpm(", i)
        if start == -1:
            break
        depth = 0
        end = -1
        j = start
        while j < len(content):
            ch = content[j]
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    end = j + 1
                    break
            j += 1

        if end == -1:
            break

        block_text = content[start:end]
        name_m = re.search(r'\bname\s*=\s*"([^"]+)"\s*,', block_text)
        sha_m = re.search(r'\bsha256\s*=\s*"([0-9a-fA-F]{64})"\s*,', block_text)
        urls_m = re.search(r'\burls\s*=\s*\[(.*?)\]\s*,', block_text, flags=re.S)
        if name_m and sha_m and urls_m:
            urls = re.findall(r'"([^"]+)"', urls_m.group(1))
            blocks.append(
                RpmBlock(
                    start=start,
                    end=end,
                    text=block_text,
                    name=name_m.group(1),
                    sha256=sha_m.group(1).lower(),
                    urls=urls,
                )
            )
        i = end
    return blocks


def replace_block_fields(block_text: str, new_name: str, new_sha: str, new_urls: List[str]) -> str:
    updated = re.sub(
        r'(\bname\s*=\s*")([^"]+)("\s*,)',
        lambda m: f'{m.group(1)}{new_name}{m.group(3)}',
        block_text,
        count=1,
    )
    updated = re.sub(
        r'(\bsha256\s*=\s*")([0-9a-fA-F]{64})("\s*,)',
        lambda m: f'{m.group(1)}{new_sha}{m.group(3)}',
        updated,
        count=1,
    )

    urls_indent = "    "
    url_lines = "\n".join(f'{urls_indent}    "{u}",' for u in new_urls)
    urls_block = f"urls = [\n{url_lines}\n{urls_indent}],"
    updated = re.sub(r'\burls\s*=\s*\[(.*?)\]\s*,', urls_block, updated, count=1, flags=re.S)
    return updated


def parse_name(name: str) -> Optional[Tuple[str, str, str]]:
    m = re.match(r"^(?P<pkg>.+)-(?P<epoch>\d+)__(?P<ver>.+\.el9\.x86_64)$", name)
    if not m:
        return None
    return m.group("pkg"), m.group("epoch"), m.group("ver")


def find_mirror_url(urls: List[str]) -> Optional[str]:
    for u in urls:
        if "/9-stream/BaseOS/x86_64/os/Packages/" in u or "/9-stream/AppStream/x86_64/os/Packages/" in u:
            return u
    return None


def is_mirror_url(url: str) -> bool:
    return "/9-stream/BaseOS/x86_64/os/Packages/" in url or "/9-stream/AppStream/x86_64/os/Packages/" in url


def pick_search_roots(mirror_url: Optional[str]) -> List[str]:
    if mirror_url and "/BaseOS/" in mirror_url:
        return [BASEOS_URL, APPSTREAM_URL]
    if mirror_url and "/AppStream/" in mirror_url:
        return [APPSTREAM_URL, BASEOS_URL]
    return [BASEOS_URL, APPSTREAM_URL]


def find_latest_rpm_url(pkg: str, current_urls: List[str]) -> Optional[str]:
    mirror_url = find_mirror_url(current_urls)
    arch_suffix = ".x86_64.rpm"

    if mirror_url:
        base_name = urllib.parse.urlparse(mirror_url).path.rsplit("/", 1)[-1]
        if base_name.endswith(".noarch.rpm"):
            arch_suffix = ".noarch.rpm"

    pattern_prefix = f"{pkg}-"
    roots = pick_search_roots(mirror_url)

    for root in roots:
        try:
            html = fetch_html(root)
        except Exception:
            continue

        parser = LinkIndexParser()
        parser.feed(html)

        candidates: List[str] = []
        for href in parser.links:
            file_name = href.split("?")[0]
            if file_name.endswith("/"):
                continue
            if not file_name.endswith(arch_suffix):
                continue
            if ".el9." not in file_name:
                continue
            if not file_name.startswith(pattern_prefix):
                continue

            remainder = file_name[len(pattern_prefix) :]
            if not remainder:
                continue
            if not remainder[0].isdigit():
                continue
            candidates.append(file_name)

        if not candidates:
            continue

        candidates.sort(key=natural_key)
        best = candidates[-1]
        return urllib.parse.urljoin(root, best)

    return None


def update_workspace_file(workspace_path: pathlib.Path, apply_changes: bool) -> Tuple[bool, Dict[str, str], List[str]]:
    content = workspace_path.read_text(encoding="utf-8")
    blocks = parse_rpm_blocks(content)

    if not blocks:
        return False, {}, []

    replacements: List[Tuple[int, int, str]] = []
    name_map: Dict[str, str] = {}
    messages: List[str] = []

    kubevirt_version = workspace_path.parent.name

    for block in blocks:
        parsed = parse_name(block.name)
        if not parsed:
            messages.append(f"[{kubevirt_version}] {block.name} -> FAIL -> unsupported-name-format")
            continue

        pkg, epoch, _ = parsed

        fallback_builddeps = f"{BUILDDEPS_PREFIX}{block.sha256}"

        existing_builddeps_urls = [u for u in block.urls if u.startswith(BUILDDEPS_PREFIX)]
        existing_mirror_urls = [u for u in block.urls if is_mirror_url(u)]
        has_single_mirror_only_url = len(block.urls) == 1 and len(existing_mirror_urls) == 1 and not existing_builddeps_urls
        has_mirror_and_builddeps_urls = bool(existing_mirror_urls) and bool(existing_builddeps_urls)

        url_status: Dict[str, bool] = {u: is_url_alive(u) for u in block.urls}
        any_existing_alive = any(url_status.values())

        # Case 1: one BaseOS/AppStream URL only. Try builddeps/<sha256>; if alive, keep version and append it.
        if has_single_mirror_only_url:
            if any_existing_alive:
                messages.append(f"[{kubevirt_version}] {block.name} -> PASS -> no-change")
                continue

            if is_url_alive(fallback_builddeps):
                new_urls = list(block.urls)
                if fallback_builddeps not in new_urls:
                    new_urls.append(fallback_builddeps)
                new_text = replace_block_fields(
                    block.text,
                    new_name=block.name,
                    new_sha=block.sha256,
                    new_urls=new_urls,
                )
                replacements.append((block.start, block.end, new_text))
                messages.append(f"[{kubevirt_version}] {block.name} -> PASS -> builddeps-added")
                continue

        # Case 2: two URLs with mirror+builddeps. Only proceed when both links are dead.
        elif has_mirror_and_builddeps_urls:
            if any_existing_alive:
                messages.append(f"[{kubevirt_version}] {block.name} -> PASS -> no-change")
                continue

        # Existing/default behavior for other URL layouts.
        else:
            if any_existing_alive:
                messages.append(f"[{kubevirt_version}] {block.name} -> PASS -> no-change")
                continue

            if is_url_alive(fallback_builddeps):
                new_text = replace_block_fields(
                    block.text,
                    new_name=block.name,
                    new_sha=block.sha256,
                    new_urls=[fallback_builddeps],
                )
                replacements.append((block.start, block.end, new_text))
                messages.append(f"[{kubevirt_version}] {block.name} -> PASS -> builddeps-switched")
                continue

        latest_url = find_latest_rpm_url(pkg, block.urls)
        if not latest_url:
            messages.append(f"[{kubevirt_version}] {block.name} -> FAIL -> no-replace")
            continue

        if not is_url_alive(latest_url):
            messages.append(f"[{kubevirt_version}] {block.name} -> FAIL -> latest-rpm-unreachable")
            continue

        latest_file = urllib.parse.urlparse(latest_url).path.rsplit("/", 1)[-1]
        if not latest_file.endswith(".rpm"):
            messages.append(f"[{kubevirt_version}] {block.name} -> FAIL -> invalid-latest-filename")
            continue

        expected_prefix = f"{pkg}-"
        if not latest_file.startswith(expected_prefix):
            messages.append(f"[{kubevirt_version}] {block.name} -> FAIL -> unexpected-latest-filename")
            continue

        new_ver = latest_file[len(expected_prefix) : -4]
        new_name = f"{pkg}-{epoch}__{new_ver}"

        try:
            new_sha = fetch_sha256(latest_url)
        except Exception as exc:
            messages.append(f"[{kubevirt_version}] {block.name} -> FAIL -> sha256-fetch-failed")
            continue

        new_urls = [latest_url, f"{BUILDDEPS_PREFIX}{new_sha}"]
        new_text = replace_block_fields(block.text, new_name=new_name, new_sha=new_sha, new_urls=new_urls)
        replacements.append((block.start, block.end, new_text))
        if new_name != block.name:
            name_map[block.name] = new_name
        messages.append(f"[{kubevirt_version}] {block.name} -> PASS -> updated={new_name}")

    if not replacements:
        return False, {}, messages

    replacements.sort(key=lambda item: item[0])
    out_parts: List[str] = []
    cursor = 0
    for start, end, new_text in replacements:
        out_parts.append(content[cursor:start])
        out_parts.append(new_text)
        cursor = end
    out_parts.append(content[cursor:])

    if apply_changes:
        workspace_path.write_text("".join(out_parts), encoding="utf-8")
    return True, name_map, messages


def update_rpm_build_file(rpm_build_path: pathlib.Path, name_map: Dict[str, str], apply_changes: bool) -> bool:
    if not name_map:
        return False

    content = rpm_build_path.read_text(encoding="utf-8")
    updated = content
    changed = False

    for old_name, new_name in name_map.items():
        old_token = f"@{old_name}//rpm"
        new_token = f"@{new_name}//rpm"
        if old_token in updated:
            updated = updated.replace(old_token, new_token)
            changed = True

    if changed and apply_changes:
        rpm_build_path.write_text(updated, encoding="utf-8")
    return changed


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate and repair CentOS 9 x86_64 RPM URLs in kubevirt-patch WORKSPACE files.")
    parser.add_argument("--root", default=".", help="Repository root")
    parser.add_argument("--check", action="store_true", help="Check mode only; do not write files")
    args = parser.parse_args()

    repo_root = pathlib.Path(args.root).resolve()
    kubevirt_patch = repo_root / "kubevirt-patch"

    if not kubevirt_patch.is_dir():
        print(f"error: missing directory: {kubevirt_patch}", file=sys.stderr)
        return 2

    workspace_paths = sorted(kubevirt_patch.glob("v*/WORKSPACE"))
    if not workspace_paths:
        print("error: no kubevirt-patch version WORKSPACE files found", file=sys.stderr)
        return 2

    any_changes = False
    all_messages: List[str] = []

    apply_changes = not args.check

    for workspace_path in workspace_paths:
        rpm_build_path = workspace_path.with_name("rpm-BUILD.bazel")
        if not rpm_build_path.exists():
            all_messages.append(f"skip: missing {rpm_build_path}")
            continue

        changed_workspace, name_map, messages = update_workspace_file(workspace_path, apply_changes=apply_changes)
        all_messages.extend(messages)

        changed_rpm_build = False
        if changed_workspace:
            changed_rpm_build = update_rpm_build_file(rpm_build_path, name_map, apply_changes=apply_changes)

        if changed_workspace or changed_rpm_build:
            any_changes = True

    for msg in all_messages:
        print(msg)

    if args.check:
        return 1 if any_changes else 0

    return 0


if __name__ == "__main__":
    sys.exit(main())
