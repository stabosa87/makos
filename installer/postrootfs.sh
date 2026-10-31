#!/usr/bin/env bash
# Configure the Anaconda Web UI inside the MakOS live installer.

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_IMAGE_PAYLOAD="${INSTALL_IMAGE_PAYLOAD:?}"

imageref="${INSTALL_IMAGE_PAYLOAD%:*}"
imagetag="${INSTALL_IMAGE_PAYLOAD##*:}"
if [[ "$imageref" == "$INSTALL_IMAGE_PAYLOAD" ]]; then
    imagetag=latest
fi

dnf5 versionlock clear >/dev/null 2>&1 || true

dnf5 install -y --allowerasing \
    anaconda-live \
    anaconda-webui \
    firefox \
    xorg-x11-xauth \
    libblockdev-btrfs \
    libblockdev-lvm \
    libblockdev-dm

mkdir -p /var/lib/rpm-state

branding_dir=/usr/share/cockpit/branding/fedora-makos
install -d "$branding_dir" /etc/cockpit/branding

for file in anaconda-branding.css anaconda-branding-compat.css; do
    for candidate in \
        "/usr/share/cockpit/branding/fedora/$file" \
        "/usr/share/cockpit/static/$file"; do
        if [[ -f "$candidate" ]]; then
            cp "$candidate" "$branding_dir/$file"
            break
        fi
    done
done

install -m 0644 "$SCRIPT_DIR/cockpit/branding.css" "$branding_dir/branding.css"
install -m 0644 /usr/share/pixmaps/makos-logo.png "$branding_dir/logo.png"
install -m 0644 "$SCRIPT_DIR/cockpit/favicon.png" "$branding_dir/favicon.ico"
install -m 0644 "$SCRIPT_DIR/cockpit/apple-touch-icon.png" "$branding_dir/apple-touch-icon.png"
install -m 0644 /usr/share/backgrounds/makosbg.png "$branding_dir/background.png"

mkdir -p /usr/share/cockpit/branding/fedora
cp -a "$branding_dir/." /usr/share/cockpit/branding/fedora/

cp -a "$branding_dir/." /etc/cockpit/branding/

install -d /etc/anaconda/profile.d
install -m 0644 \
    "$SCRIPT_DIR/system_files/etc/anaconda/profile.d/zz-makos.conf" \
    /etc/anaconda/profile.d/zz-makos.conf

install -d /etc/anaconda/cockpit/conf.d
cat >/etc/anaconda/cockpit/conf.d/50-makos.conf <<'EOF'
[WebService]
LoginTitle = MakOS Installer
EOF

install -d /usr/share/anaconda
printf '\n' >>/usr/share/anaconda/interactive-defaults.ks
cat >>/usr/share/anaconda/interactive-defaults.ks <<EOF
ostreecontainer --url=${imageref}:${imagetag} --transport=containers-storage --no-signature-verification

%post --erroronfail --log=/tmp/makos-bootc-switch.log
bootc switch --mutate-in-place --transport registry ${imageref}:${imagetag}
%end

%post
. /usr/lib/os-release
echo "\${DEFAULT_HOSTNAME:-makos}" > /etc/hostname
%end
EOF

for service in \
    rpm-ostree-countme.service \
    bootloader-update.service \
    rpm-ostreed-automatic.timer \
    uupd.timer \
    flatpak-manager.service \
    ublue-flatpak-manager.service \
    ublue-user-setup.service; do
    systemctl disable "$service" 2>/dev/null || true
done

sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' \
    /usr/share/anaconda/gnome/org.fedoraproject.welcome-screen.desktop 2>/dev/null || true

rm -f /usr/bin/rpm-ostree

cp -a "$SCRIPT_DIR/system_files/usr/share/icons/." /usr/share/icons/
gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true

dnf5 clean all
