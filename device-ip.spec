
Name:        device-ip
Summary:     Device IP (ip4, ip6 (and mac)) information
Version:     1.1
Release:     2
License:     BSD-2-Clause
Requires:    sailfishsilica-qt5 >= 0.10.9
Requires:    pyotherside-qml-plugin-python3-qt5
Requires:    libsailfishapp-launcher
BuildArch:   noarch
BuildRequires:  desktop-file-utils


%description
Show network addresses of the interfaces that are UP.


%prep
sed '$q; s/^/: /' "$0"
#env
#id
#%setup -q -n %{name}-%{version}
#%setup -q
#cp $OLDPWD/device-ip* .


%build
# nothing to build -- even python is code embedded in qml

%install
set -euf
# protection around "user error" with --buildroot=$PWD (tried before
# --build-in-place) -- rpmbuild w/o sudo and container image default
# uid/gid saved me from deleting all files from current directory).
# "inverse logic" even though it is highly unlikely rm -rf fails...
test ! -f %{buildroot}/device-ip.qml && rm -rf %{buildroot} ||
rm -rf %{buildroot}%{_datadir}
mkdir -p %{buildroot}%{_datadir}/
mkdir %{buildroot}%{_datadir}/%{name}/ \
      %{buildroot}%{_datadir}/%{name}/qml/ \
      %{buildroot}%{_datadir}/applications/ \
      %{buildroot}%{_datadir}/icons/ \
      %{buildroot}%{_datadir}/icons/hicolor/ \
      %{buildroot}%{_datadir}/icons/hicolor/86x86/ \
      %{buildroot}%{_datadir}/icons/hicolor/86x86/apps/
install -m 644 device-ip.qml device-ip.py %{buildroot}%{_datadir}/%{name}/qml/.
install -m 644 device-ip.png \
        %{buildroot}%{_datadir}/icons/hicolor/86x86/apps/.
install -m 644 device-ip.desktop %{buildroot}%{_datadir}/applications/.

set +f
desktop-file-install --delete-original \
        --dir %{buildroot}%{_datadir}/applications \
        %{buildroot}%{_datadir}/applications/*.desktop


%clean
set -euf
# protection around "user error" with --buildroot=$PWD ...
test ! -f %{buildroot}/device-ip.qml && rm -rf %{buildroot} ||
rm -rf %{buildroot}%{_datadir}


%files
%defattr(-,root,root,-)
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/86x86/apps/%{name}.png
