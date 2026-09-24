# Edge Desktop Virtualization Skill for Coding Agents

Use this file when helping a user enable, customize, or troubleshoot desktop virtualization with Intel graphics SR-IOV using this repository.

## Start Here

This repository is not a single application. It is a solution stack made up of:

- host-side setup and launch scripts for local-display VMs
- a Kubernetes device plugin that exposes host resources to workloads
- KubeVirt patch guidance and versioned patch overlays
- sample manifests and Helm charts for guest image creation and VM deployment
- documentation that ties the full flow together

For the end-to-end workflow, start with [README.md](README.md).

## Repository Map

- [README.md](README.md): top-level architecture, prerequisites, and the order in which the solution is assembled
- [docs/](docs): supporting setup guides, host configuration, and images referenced by the main docs
- [device-plugins-for-kubernetes/](device-plugins-for-kubernetes): the only compiled code in this repo; Go-based Kubernetes device plugin plus manifests and Helm chart
- [idv-services/](idv-services): host-side systemd services and shell scripts that initialize SR-IOV/display state and launch VMs
- [kubevirt-patch/](kubevirt-patch): instructions plus version-specific patch overlay files for building KubeVirt with patched QEMU and local GTK display support
- [sample-application/](sample-application): guest boot disk creation manifests and VM deployment examples for both discrete-monitor and single-Helm flows

## What To Edit For Common Requests

- **Expose or change Kubernetes resources**  
  Start in [device-plugins-for-kubernetes/pkg/resources](device-plugins-for-kubernetes/pkg/resources), then update deployment artifacts under `device-plugins-for-kubernetes/deploy/`.

- **Change device plugin startup, registration, or kubelet interaction**  
  Start in [device-plugins-for-kubernetes/cmd/main.go](device-plugins-for-kubernetes/cmd/main.go) and [device-plugins-for-kubernetes/pkg/grpcserver](device-plugins-for-kubernetes/pkg/grpcserver).

- **Adjust host initialization or VM launch behavior**  
  Start in [idv-services/init](idv-services/init), [idv-services/launcher](idv-services/launcher), and the user services under [idv-services/etc/systemd/user](idv-services/etc/systemd/user).

- **Change packaged host-service delivery**  
  Update [idv-services/intel-idv-services.spec](idv-services/intel-idv-services.spec) and related scripts in `idv-services/`.

- **Change VM defaults, sidecar display settings, or deployment examples**  
  Start in [sample-application/discrete](sample-application/discrete), [sample-application/single](sample-application/single), or [sample-application/create-bootdisk](sample-application/create-bootdisk).

- **Update KubeVirt patch guidance or supported versions**  
  Start in [kubevirt-patch/README.md](kubevirt-patch/README.md) and the matching version directory under `kubevirt-patch/`.

- **Update setup or user guidance**  
  Prefer editing the nearest README or guide already covering that workflow instead of duplicating instructions elsewhere.

## Domain Rules

- This project assumes Intel graphics SR-IOV on supported hardware; the root README currently calls out Alder Lake or newer.
- `DISPLAY`, monitor connector names like `HDMI-1` or `DP-3`, USB bus/port mappings, and local image paths are host-specific. Do not replace them blindly across the repo without confirming the intended target environment.
- Most changes in this repository are documentation, YAML, Helm, or shell updates. Only `device-plugins-for-kubernetes/` contains Go code that is built and unit tested here.
- Versioned files in `kubevirt-patch/` are tied to specific KubeVirt releases. Keep changes scoped to the version the user actually needs.

## Validation

- **Device plugin code changes:** from `device-plugins-for-kubernetes/`, use `make build`, `make test`, and `make fmt`; use `make check` when you need the full existing validation path.
- **Shell script changes:** run the existing `shellcheck` path via pre-commit if it is available for the files you changed.
- **Go or shell hygiene:** the repo pre-commit config includes `gitleaks`, `golangci-lint`, `shellcheck`, `end-of-file-fixer`, and `trailing-whitespace`.
- **Docs-only changes:** verify links, paths, and section references instead of inventing extra tooling.

## Agent Rules

- Use the root README to place user requests in the full workflow before editing a leaf component.
- Prefer the existing examples and manifests over new abstractions.
- Keep hardware-specific values configurable and localized.
- When a request spans multiple layers, update both the implementation and the closest user-facing guide that explains that workflow.
