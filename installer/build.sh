#!/usr/bin/env bash

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_IMAGE="${BASE_IMAGE:?}"
INSTALL_IMAGE_PAYLOAD="${INSTALL_IMAGE_PAYLOAD:-$BASE_IMAGE}"

mkdir -p "$(realpath /root)"

mount -o remount,rw /proc/sys 2>/dev/null || true

if ! command -v podman >/dev/null 2>&1; then
    dnf5 install -y podman
fi

if mountpoint -q /usr/lib/containers/storage; then
    podman save --format oci-archive "$INSTALL_IMAGE_PAYLOAD" |
        podman load --storage-opt additionalimagestore=''
else
    podman pull "$INSTALL_IMAGE_PAYLOAD"
fi

cp -a /src/system_files/. /
gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true

dnf5 versionlock clear >/dev/null 2>&1 || true

dnf5 install -y dracut-live livesys-scripts

KERNEL_VERSION="$(rpm -q --queryformat='%{evr}.%{arch}' kernel-core)"
export DRACUT_NO_XATTR=1
dracut -v --force --zstd --reproducible --no-hostonly \
    --add "dmsquash-live dmsquash-live-autooverlay" \
    -f "/usr/lib/modules/${KERNEL_VERSION}/initramfs.img" "${KERNEL_VERSION}"

if grep -q '^livesys_session=' /etc/sysconfig/livesys; then
    sed -i 's/^livesys_session=.*/livesys_session=gnome/' /etc/sysconfig/livesys
else
    echo 'livesys_session=gnome' >>/etc/sysconfig/livesys
fi
systemctl enable livesys.service livesys-late.service

"$SCRIPT_DIR/postrootfs.sh"
case "$(uname -m)" in
    x86_64)
        dnf5 install -y grub2-efi-x64-cdboot
        ;;
    aarch64)
        dnf5 install -y grub2-efi-aa64-cdboot
        ;;
    *)
        echo "Unsupported architecture: $(uname -m)" >&2
        exit 1
        ;;
esac

mkdir -p /boot/efi
if compgen -G "/usr/lib/efi/*/*/EFI" >/dev/null; then
    cp -av /usr/lib/efi/*/*/EFI /boot/efi/
fi

if [[ -f /boot/efi/EFI/fedora/grubx64.efi ]]; then
    cp -v /boot/efi/EFI/fedora/grubx64.efi /boot/efi/EFI/BOOT/fbx64.efi || true
fi

rm -f /etc/localtime
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

rm -rf /var/tmp
mkdir /var/tmp
cat >/etc/systemd/system/var-tmp.mount <<'EOF'
[Unit]
Description=Larger tmpfs for /var/tmp on the live system

[Mount]
What=tmpfs
Where=/var/tmp
Type=tmpfs
Options=size=50%%,nr_inodes=1m,x-systemd.graceful-option=usrquota

[Install]
WantedBy=local-fs.target
EOF
systemctl enable var-tmp.mount

mkdir -p /var/lib/flatpak
cat >/etc/systemd/system/var-lib-flatpak.mount <<'EOF'
[Unit]
Description=Read-only Flatpak installation on the live system

[Mount]
Type=none
What=/var/lib/flatpak
Where=/var/lib/flatpak
Options=bind,ro

[Install]
WantedBy=multi-user.target
EOF
systemctl enable var-lib-flatpak.mount

mkdir -p /usr/lib/bootc-image-builder
cp /src/iso.yaml /usr/lib/bootc-image-builder/iso.yaml

dnf5 clean all
rm -rf /var/cache/dnf /var/cache/libdnf5 /var/tmp/* 2>/dev/null || true
