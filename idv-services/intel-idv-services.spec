Name:           intel-idv-services
Version:        0.1
Release:        1%{?dist}
Summary:        A package to install scripts and systemd services for Intelligent Desktop Virtualization(IDV)
Distribution:   Edge Microvisor Toolkit
Vendor:         Intel Corporation
License:        Apache-2.0
URL:            https://github.com/open-edge-platform/edge-desktop-virtualization
Source0:        %{name}-%{version}.tar.gz

BuildArch:       noarch
BuildRequires:   systemd-rpm-macros
Requires(post):  systemd
Requires(preun): systemd

%description
This package installs the scripts and services that are needed to run IDV solution

%prep
%setup -q

%build

%install
# Copy the scripts folder to bindir
mkdir -p %{buildroot}%{_bindir}/idv
cp -r init %{buildroot}%{_bindir}/idv
cp -r launcher %{buildroot}%{_bindir}/idv

# Install the idv-init service. This service sets up the environment required for running virtual machines
mkdir -p %{buildroot}%{_userunitdir}
install -m 644 idv-init.service %{buildroot}%{_userunitdir}/idv-init.service

# Install the idv-launcher service. This service launches virtual machines based on the configuration specified in the launcher/vm.conf file.      
install -m 644 idv-launcher.service %{buildroot}%{_userunitdir}/idv-launcher.service

# Install the autologin.conf file. This enables autologin for a specified user.
mkdir -p %{buildroot}%{_sysconfdir}/systemd/system/getty@tty1.service.d
install -m 644 autologin.conf %{buildroot}%{_sysconfdir}/systemd/system/getty@tty1.service.d/autologin.conf

%files
/usr/bin/idv/*
/usr/lib/systemd/user/idv-*.service
%config(noreplace) /etc/systemd/system/getty@tty1.service.d/autologin.conf

%post
systemctl daemon-reload

USER_ID=1000
USER=$(getent passwd 1000 | cut -d: -f1)
export XDG_RUNTIME_DIR=/run/user/$USER_ID
if [ -d "$XDG_RUNTIME_DIR" ]; then
    sudo -u $USER XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR systemctl --user daemon-reload
    sudo -u $USER XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR systemctl --user enable idv-init.service
    sudo -u $USER XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR systemctl --user start idv-init.service
    sudo -u $USER XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR systemctl --user enable idv-launcher.service
    sudo -u $USER XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR systemctl --user start idv-launcher.service
fi

%preun
set -e
# Stop and disable the idv-init service before uninstalling
if [ $1 -eq 0 ]; then
    USER_ID=$(id -u $SUDO_USER)
    export XDG_RUNTIME_DIR=/run/user/$USER_ID
    if [ -d "$XDG_RUNTIME_DIR" ]; then
        sudo -u $SUDO_USER XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR systemctl --user stop idv-init.service
        sudo -u $SUDO_USER XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR systemctl --user disable idv-init.service

        sudo -u $SUDO_USER XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR systemctl --user stop idv-launcher.service
        sudo -u $SUDO_USER XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR systemctl --user disable idv-launcher.service
    fi
fi

%changelog
* Fri Jun 20 2025 Dhanya A <dhanya.a@intel.com> - 0.1-6
- Update comment in spec file

* Thu Jun 19 2025 Dhanya A <dhanya.a@intel.com> - 0.1-5
- Copy scripts to bin directory, use macros for standard path, remove logs file

* Tue Jun 17 2025 Dhanya A <dhanya.a@intel.com> - 0.1-3
- Remove command to create logs file.

* Mon Jun 16 2025 Dhanya A <dhanya.a@intel.com> - 0.1-2
- Initial Edge Microvisor Toolkit import from Fedora 43 (license: MIT). License verified.

* Fri Jun 13 2025 Dhanya A <dhanya.a@intel.com> - 0.1-1
- Initial RPM package for scripts and systemd services
