#!/usr/bin/bash
#
# flavor: nvidia drivers

set -eoux pipefail

: "${NVIDIA_DRIVER_FLAVOR:=nvidia-lts}"
: "${AKMODS_FLAVOR:=main}"

case "${NVIDIA_DRIVER_FLAVOR}" in
    nvidia-lts | nvidia-open) ;;
    *)
        echo "Unsupported NVIDIA driver flavor: ${NVIDIA_DRIVER_FLAVOR}" >&2
        exit 1
        ;;
esac

echo "::group:: Installing nvidia drivers (${NVIDIA_DRIVER_FLAVOR})"

FEDORA_VERSION="$(rpm -E %fedora)"
KERNEL_VERSION="$(rpm -q --queryformat='%{evr}.%{arch}' kernel-core)"
AKMODS_IMAGE="ghcr.io/ublue-os/akmods-${NVIDIA_DRIVER_FLAVOR}:${AKMODS_FLAVOR}-${FEDORA_VERSION}-${KERNEL_VERSION}"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

echo "Fetching ${AKMODS_IMAGE}"
if ! skopeo copy --retry-times 3 "docker://${AKMODS_IMAGE}" "dir:${WORKDIR}/akmods"; then
    echo "Failed to fetch ${AKMODS_IMAGE}." >&2
    echo "The base image kernel may not have a matching akmods build yet." >&2
    exit 1
fi

mkdir -p "${WORKDIR}/akmods-root"
while read -r layer; do
    tar -xzf "${WORKDIR}/akmods/${layer#sha256:}" -C "${WORKDIR}/akmods-root"
done < <(jq -r '.layers[].digest' "${WORKDIR}/akmods/manifest.json")

export AKMODNV_PATH="${WORKDIR}/akmods-root/rpms"

dnf5 config-manager setopt excludepkgs=golang-github-nvidia-container-toolkit || true

IMAGE_NAME="silverblue" MULTILIB="${MULTILIB:-0}" "${AKMODNV_PATH}/ublue-os/nvidia-install.sh"

rpm -q kmod-nvidia nvidia-driver nvidia-driver-cuda >/dev/null

rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so

mkdir -p /usr/lib/bootc/kargs.d
cat > /usr/lib/bootc/kargs.d/00-nvidia.toml <<'EOF'
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF

if [[ -f /usr/lib/dracut/dracut.conf.d/99-nvidia.conf ]]; then
    sed -i 's/ nvidia_peermem\b//' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf
fi

if [[ -f /etc/modprobe.d/nvidia-modeset.conf ]]; then
    cp /etc/modprobe.d/nvidia-modeset.conf /usr/lib/modprobe.d/nvidia-modeset.conf
fi

echo "::endgroup::"
