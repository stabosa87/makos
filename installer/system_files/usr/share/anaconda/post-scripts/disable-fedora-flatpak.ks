%post --erroronfail --log=/tmp/makos-disable-fedora-flatpak.log
systemctl disable flatpak-add-fedora-repos.service 2>/dev/null || true
%end
