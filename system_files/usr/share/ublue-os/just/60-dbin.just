# Install dbin home package manager
[group('Installation')]
install-dbin:
    wget -qO- "https://raw.githubusercontent.com/xplshn/dbin/master/stubdl" | sh -s -- --install "$HOME/.local/bin/dbin"