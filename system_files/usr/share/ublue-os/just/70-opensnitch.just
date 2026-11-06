install-opensnitch:
    #!/usr/bin/bash
    set -euo pipefail

    BASE_URL="https://github.com/evilsocket/opensnitch/releases/download/v1.8.0"

    ARCH="$(uname -m)"

    case "$ARCH" in
        x86_64) RPM_ARCH="x86_64" ;;
        aarch64) RPM_ARCH="aarch64" ;;
        armv7l|armv7hl) RPM_ARCH="armv7hnl" ;;
        i386|i686) RPM_ARCH="i386" ;;
        *)
            echo "Unsupported architecture $ARCH"
            exit 1
            ;;
    esac

    TMPDIR="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR"' EXIT

    echo "Detected $ARCH"
    echo "Downloading OpenSnitch..."

    curl -fL "$BASE_URL/opensnitch-ui-1.8.0-1.noarch.rpm" \
        -o "$TMPDIR/opensnitch-ui.rpm"

    curl -fL "$BASE_URL/opensnitch-1.8.0-1.$RPM_ARCH.rpm" \
        -o "$TMPDIR/opensnitch-daemon.rpm"

    echo "Installing OpenSnitch..."

    sudo rpm-ostree install \
        "$TMPDIR/opensnitch-daemon.rpm" \
        "$TMPDIR/opensnitch-ui.rpm"

    sudo systemctl enable opensnitch.service

    echo ""
    echo "OpenSnitch has been staged for installation."
    echo "Reboot to activate the new deployment."