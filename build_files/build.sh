#!/bin/bash

set -ouex pipefail

cp -avf "/ctx/system_files"/. /
MAKOS_HOSTNAME="$(cat /etc/hostname 2>/dev/null || echo makos)"
dnf5 -y copr enable stabosa87/makos

dnf5 install -y vim approller fastfetch gnome-shell-extension-blur-my-shell gnome-shell-extension-gsconnect gnome-shell-extension-appindicator

dnf5 remove -y gnome-shell-extension-background-logo gnome-software

dnf5 install -y --setopt=install_weak_deps=False gnome-initial-setup
systemctl enable gdm || true
systemctl set-default graphical.target || true
rm -f /var/lib/gnome-initial-setup-done

glib-compile-schemas /usr/share/glib-2.0/schemas
gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true

if command -v dconf >/dev/null 2>&1; then
    dconf update
fi

if [[ -f /usr/lib/os-release ]]; then
    sed -i \
        -e 's/^NAME=.*/NAME="MakOS"/' \
        -e 's/^PRETTY_NAME=.*/PRETTY_NAME="MakOS"/' \
        -e 's/^VARIANT=.*/VARIANT="MakOS"/' \
        -e 's/^VARIANT_ID=.*/VARIANT_ID="makos"/' \
        -e 's/^DEFAULT_HOSTNAME=.*/DEFAULT_HOSTNAME="makos"/' \
        -e 's/^BOOTLOADER_NAME=.*/BOOTLOADER_NAME="MakOS"/' \
        -e 's/^LOGO=.*/LOGO=makos-logo/' \
        /usr/lib/os-release

    if ! grep -q '^LOGO=' /usr/lib/os-release; then
        echo 'LOGO=makos-logo' >> /usr/lib/os-release
    fi

    # shellcheck disable=SC1091
    . /usr/lib/os-release
    echo "MakOS release ${VERSION_ID} (${VERSION_CODENAME:-MakOS})" >/etc/system-release
fi

flatpak remote-add --system --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install --system --noninteractive --assumeyes \
    flathub it.mijorus.gearlever \
    io.github.kolunmi.Bazaar

rm -rf /var/tmp/flatpak-* /var/cache/flatpak /var/log/flatpak* 2>/dev/null || true

mkdir -p /var/roothome
chmod 0700 /var/roothome
KERNEL_VERSION="$(rpm -q --queryformat='%{evr}.%{arch}' kernel-core)"
export DRACUT_NO_XATTR=1
dracut --no-hostonly --kver "${KERNEL_VERSION}" --reproducible --add ostree \
    -f "/lib/modules/${KERNEL_VERSION}/initramfs.img"
chmod 0600 "/lib/modules/${KERNEL_VERSION}/initramfs.img"

