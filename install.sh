#!/usr/bin/env bash
# epic dotfiles installer (very experimental)
#
# Best-effort by design: a step that fails prints a warning and the run keeps
# going, so one dead upstream mirror does not cost you the whole install.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TOTAL=21
STEP=0
FAILED=()
NOTES=()

if [ -t 1 ] && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    BOLD="$(tput bold)"; DIM="$(tput dim)"; RESET="$(tput sgr0)"
    RED="$(tput setaf 1)"; GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"; BLUE="$(tput setaf 4)"
else
    BOLD=""; DIM=""; RESET=""; RED=""; GREEN=""; YELLOW=""; BLUE=""
fi

# step <title> [one-sentence explanation]
step() {
    STEP=$(( STEP + 1 ))
    printf '\n%s%s[%2d/%d]%s %s%s%s\n' "$BOLD" "$BLUE" "$STEP" "$TOTAL" "$RESET" "$BOLD" "$1" "$RESET"
    [ -n "${2:-}" ] && printf '       %s%s%s\n' "$DIM" "$2" "$RESET"
    CURRENT="$1"
}
ok()   { printf '       %s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '       %s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
fail() { printf '       %s✗%s %s\n' "$RED" "$RESET" "$*"; FAILED+=("$CURRENT"); }
# run <command...> - report the outcome instead of aborting the installer
run()  { if "$@"; then ok "$CURRENT"; else fail "$CURRENT failed (exit $?)"; fi; }
# note <text> - queued for the manual-steps list printed at the end
note() { NOTES+=("$*"); }

printf '%s%sepic dotfiles installer%s %s(very experimental)%s\n' "$BOLD" "$GREEN" "$RESET" "$DIM" "$RESET"

step "Refreshing dnf metadata"
run sudo dnf upgrade --refresh -y

step "Enabling Copr repositories" "Third-party builds of SwayNC, starship, and the Framework EC tool."
sudo dnf copr enable -y erikreider/SwayNotificationCenter
sudo dnf copr enable -y atim/starship
sudo dnf copr enable -y rowanfr/fw-ectool
ok "Copr repositories enabled"

step "Installing Hyprland"
run sudo dnf install -y hyprland hyprland-devel

step "Installing packages and build dependencies" "Everything from dnf in one transaction: the desktop bits plus the headers the source builds below need."
run sudo dnf install -y dnf5-plugins make gcc golang glib2-devel cairo-devel \
    cairo-gobject-devel gobject-introspection-devel atk-devel gdk-pixbuf2-devel \
    python3-gobject-devel pango-devel gtk3-devel gtk-layer-shell-devel \
    pulseaudio-libs pulseaudio-libs-devel cxxopts jq pkgconf-pkg-config \
    stow starship wlogout dolphin flameshot waybar hyprpaper zsh vim blueman \
    fastfetch SwayNotificationCenter

step "Setting zsh as the login shell"
if chsh -s "$(which zsh)"; then
    ok "login shell set to zsh"
    note "Log out and back in for zsh to become your shell."
else
    fail "chsh failed"
fi

step "Installing Meson and Ninja" "Build system for pamixer, further down."
run python3 -m pip install --user meson ninja

step "Installing Vicinae"
run bash -c 'curl -fsSL https://vicinae.com/install.sh | bash'

step "Installing Kitty"
if curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin; then
    kitten themes 'Gruvbox Material Dark Medium' && ok "Kitty installed, Gruvbox theme applied"
else
    fail "Kitty install failed"
fi

step "Installing Avizo" "On-screen volume and brightness popups."
sudo dnf copr enable -y tswsl1989/tswsl-wayland-extras
run sudo dnf install -y avizo

step "Building nwg-dock-hyprland"
if git clone https://github.com/nwg-piotr/nwg-dock-hyprland /tmp/nwg-dock-hyprland \
    && make -C /tmp/nwg-dock-hyprland get build \
    && sudo make -C /tmp/nwg-dock-hyprland install; then
    ok "nwg-dock-hyprland installed"
else
    fail "nwg-dock-hyprland build failed"
fi
rm -rf /tmp/nwg-dock-hyprland

step "Building pamixer" "Waybar's volume module shells out to this."
if git clone https://github.com/cdemoulins/pamixer.git /tmp/pamixer \
    && meson setup /tmp/pamixer/build /tmp/pamixer \
    && meson compile -C /tmp/pamixer/build \
    && sudo meson install -C /tmp/pamixer/build; then
    ok "pamixer installed"
else
    fail "pamixer build failed"
fi
rm -rf /tmp/pamixer

step "Building nwg-look" "GTK theme picker; Hyprland has no settings GUI of its own."
if git clone https://github.com/nwg-piotr/nwg-look /tmp/nwg-look \
    && make -C /tmp/nwg-look build \
    && sudo make -C /tmp/nwg-look install; then
    ok "nwg-look installed"
else
    fail "nwg-look build failed"
fi
rm -rf /tmp/nwg-look

step "Installing VSCode"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
printf '[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n' \
    | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
run sudo dnf install -y code

step "Installing the 0xProto Nerd Font"
if wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/0xProto.zip -O /tmp/0xProto.zip \
    && unzip -q /tmp/0xProto.zip -d /tmp/0xProto \
    && sudo cp -r /tmp/0xProto /usr/share/fonts/ \
    && sudo fc-cache -f; then
    ok "0xProto installed"
else
    fail "font install failed"
fi
rm -rf /tmp/0xProto.zip /tmp/0xProto

step "Installing Spotify and Spicetify"
if flatpak install -y flathub com.spotify.Client; then
    curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
    curl -fsSL https://raw.githubusercontent.com/spicetify/marketplace/main/resources/install.sh | sh
    spicetify config prefs_path ~/.var/app/com.spotify.Client/config/spotify/prefs
    SPOTIFY_DIR=/var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify
    sudo chmod a+wr "$SPOTIFY_DIR"
    sudo chmod a+wr -R "$SPOTIFY_DIR/Apps"
    ok "Spotify installed, Spicetify configured"
    note "Launch Spotify once, then run: spicetify backup apply"
else
    fail "Spotify install failed"
fi

step "Installing the GitHub CLI"
sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
if sudo dnf install -y gh --repo gh-cli; then
    ok "gh installed"
    note "Authenticate with: gh auth login"
else
    fail "gh install failed"
fi

step "Installing Tailscale"
if curl -fsSL https://tailscale.com/install.sh | sh; then
    ok "Tailscale installed"
    note "Join your tailnet with: sudo tailscale up"
else
    fail "Tailscale install failed"
fi

step "Installing dark mode theming" "Themes only; GTK and Qt each need to be pointed at them by hand."
run sudo dnf install -y adw-gtk3-theme qt5ct qt6ct kvantum breeze-icons
note "Pick the GTK theme in nwg-look, and the Qt one in qt5ct/qt6ct (style: kvantum)."

step "Installing the Framework EC charge limit service" "Caps the battery at 80% to slow wear."
if sudo cp "$REPO_DIR/system/ec-charge-limit.service" /etc/systemd/system/ \
    && sudo systemctl enable --now ec-charge-limit.service; then
    ok "ec-charge-limit.service enabled"
else
    fail "charge limit service failed"
fi

step "Linking the configuration" "stow symlinks config/ into ~/.config."
if stow -d "$REPO_DIR" config; then
    ok "config linked"
    hyprctl reload >/dev/null 2>&1 && ok "Hyprland reloaded"
else
    fail "stow failed"
fi

step "Building the Hyprspace overview plugin" "Pins itself to the Hyprspace commit matching your Hyprland version."
if command -v hyprctl >/dev/null && hyprctl version >/dev/null 2>&1; then
    run "$REPO_DIR/install-hyprspace.sh"
else
    warn "no Hyprland session detected - skipped"
    note "Run ./install-hyprspace.sh once you are logged into Hyprland."
fi

printf '\n%s%s────────────────────────────────────────%s\n' "$BOLD" "$BLUE" "$RESET"
if [ ${#FAILED[@]} -eq 0 ]; then
    printf '%s%sAll %d steps completed.%s\n' "$BOLD" "$GREEN" "$TOTAL" "$RESET"
else
    printf '%s%s%d step(s) failed:%s\n' "$BOLD" "$RED" "${#FAILED[@]}" "$RESET"
    for f in "${FAILED[@]}"; do printf '  %s✗%s %s\n' "$RED" "$RESET" "$f"; done
fi

note "Log out and select Hyprland from your display manager's session picker."
printf '\n%s%sManual steps left for you:%s\n' "$BOLD" "$YELLOW" "$RESET"
i=0
for n in "${NOTES[@]}"; do i=$(( i + 1 )); printf '  %s%d.%s %s\n' "$BOLD" "$i" "$RESET" "$n"; done
printf '\n'
