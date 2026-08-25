#!/usr/bin/env bash
# epic dotfiles installer (very experimental)
#
# Output is quiet by default: each step shows a spinner and a one-line verdict,
# with the full output tucked into a log that is only replayed when something
# fails. Run with VERBOSE=1 ./install.sh to watch everything stream past.
#
# Best-effort by design - a failing step is reported and the run continues, so
# one dead upstream mirror does not cost you the whole install.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="${TMPDIR:-/tmp}/dotfiles-install.$$.log"
TOTAL=20
STEP=0
FAILED=()
NOTES=()
CURRENT=""
SPIN_PID=""

if [ -t 1 ] && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    BOLD="$(tput bold)"; DIM="$(tput dim)"; RESET="$(tput sgr0)"
    RED="$(tput setaf 1)"; GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"; BLUE="$(tput setaf 4)"
    TTY=1
else
    BOLD=""; DIM=""; RESET=""; RED=""; GREEN=""; YELLOW=""; BLUE=""
    TTY=""
fi

rule() { printf '%s%s%s%s\n' "$DIM" "$BLUE" "$(printf '─%.0s' $(seq 1 "${COLUMNS:-56}"))" "$RESET"; }

# step <title> [one-sentence explanation]
step() {
    STEP=$(( STEP + 1 ))
    CURRENT="$1"
    printf '\n%s%s[%2d/%d]%s %s%s%s\n' "$BOLD" "$BLUE" "$STEP" "$TOTAL" "$RESET" "$BOLD" "$1" "$RESET"
    [ -n "${2:-}" ] && printf '        %s%s%s\n' "$DIM" "$2" "$RESET"
    return 0
}
ok()   { printf '        %s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '        %s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
fail() { printf '        %s✗%s %s\n' "$RED" "$RESET" "$*"; FAILED+=("$CURRENT"); }
note() { NOTES+=("$*"); }

FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
spin_start() {
    [ -n "$TTY" ] && [ -z "${VERBOSE:-}" ] || return 0
    local began=$SECONDS
    (
        trap 'exit 0' TERM
        local i=0
        while :; do
            printf '\r        %s%s%s %s (%ss)%s ' \
                "$BLUE" "${FRAMES[i % 10]}" "$RESET" "$DIM" "$(( SECONDS - began ))" "$RESET"
            i=$(( i + 1 ))
            sleep 0.12
        done
    ) &
    SPIN_PID=$!
}
spin_stop() {
    [ -n "$SPIN_PID" ] || return 0
    kill "$SPIN_PID" 2>/dev/null
    wait "$SPIN_PID" 2>/dev/null
    SPIN_PID=""
    printf '\r\033[2K'
}

# run <command...> - quiet by default, replays the tail of the log on failure.
# Takes a function name just as happily as a binary, which is how the
# multi-command source builds below stay on one line.
run() {
    local began=$SECONDS rc
    printf '\n==> %s <==\n' "$CURRENT" >> "$LOG"
    if [ -n "${VERBOSE:-}" ]; then
        "$@" 2>&1 | tee -a "$LOG" | sed "s/^/        ${DIM}/;s/\$/${RESET}/"
        rc=${PIPESTATUS[0]}
    else
        spin_start
        "$@" >> "$LOG" 2>&1
        rc=$?
        spin_stop
    fi
    local took=$(( SECONDS - began ))
    if [ "$rc" -eq 0 ]; then
        ok "$CURRENT $(printf '%s(%ss)%s' "$DIM" "$took" "$RESET")"
    else
        fail "$CURRENT failed (exit $rc)"
        printf '        %slast lines of %s:%s\n' "$DIM" "$LOG" "$RESET"
        tail -n 12 "$LOG" | sed "s/^/          ${DIM}/;s/\$/${RESET}/"
    fi
    return 0
}

cleanup() { spin_stop; [ -n "${SUDO_KEEPALIVE:-}" ] && kill "$SUDO_KEEPALIVE" 2>/dev/null; }
trap cleanup EXIT INT TERM

printf '\n%s%sepic dotfiles installer%s %s(very experimental)%s\n' "$BOLD" "$GREEN" "$RESET" "$DIM" "$RESET"
printf '%slog: %s%s\n' "$DIM" "$LOG" "$RESET"
[ -z "${VERBOSE:-}" ] && printf '%sre-run with VERBOSE=1 to stream every command%s\n' "$DIM" "$RESET"

# asked for once, up front, so no later step blocks on a hidden password prompt
printf '\n%sAdministrator password is needed for the package steps.%s\n' "$DIM" "$RESET"
sudo -v || { printf '%s✗ sudo declined - nothing installed.%s\n' "$RED" "$RESET"; exit 1; }
( while :; do sudo -n true; sleep 50; done ) 2>/dev/null &
SUDO_KEEPALIVE=$!

step "Refreshing dnf metadata" "dnf5-plugins first: the copr subcommand used in the next step lives there."
run sudo dnf install -y dnf5-plugins
run sudo dnf upgrade --refresh -y

enable_coprs() {
    sudo dnf copr enable -y erikreider/SwayNotificationCenter &&
    sudo dnf copr enable -y atim/starship &&
    sudo dnf copr enable -y rowanfr/fw-ectool
}
step "Enabling Copr repositories" "Third-party builds of SwayNC, starship, and the Framework EC tool."
run enable_coprs

step "Installing Hyprland"
run sudo dnf install -y hyprland hyprland-devel

step "Installing packages and build dependencies" "Everything from dnf in one transaction: the desktop bits plus the headers the source builds below need."
run sudo dnf install -y make gcc golang glib2-devel cairo-devel \
    cairo-gobject-devel gobject-introspection-devel atk-devel gdk-pixbuf2-devel \
    python3-gobject-devel pango-devel gtk3-devel gtk-layer-shell-devel \
    pulseaudio-libs pulseaudio-libs-devel cxxopts jq pkgconf-pkg-config \
    git curl wget unzip flatpak meson ninja-build fw-ectool btop \
    stow starship wlogout dolphin flameshot waybar hyprpaper zsh vim blueman \
    fastfetch SwayNotificationCenter

step "Setting zsh as the login shell"
run chsh -s "$(command -v zsh)"
note "Log out and back in for zsh to become your shell."

step "Installing Vicinae"
run bash -c 'curl -fsSL https://vicinae.com/install.sh | bash'

install_kitty() {
    curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin || return 1
    # the installer drops kitty in ~/.local/kitty.app; this shell has not seen it yet
    export PATH="${HOME}/.local/kitty.app/bin:${PATH}"
    kitten themes 'Gruvbox Material Dark Medium'
}
step "Installing Kitty" "Gruvbox Material Dark Medium is applied straight after."
run install_kitty

install_avizo() {
    sudo dnf copr enable -y tswsl1989/tswsl-wayland-extras &&
    sudo dnf install -y avizo
}
step "Installing Avizo" "On-screen volume and brightness popups."
run install_avizo

build_nwg_dock() {
    rm -rf /tmp/nwg-dock-hyprland &&
    git clone https://github.com/nwg-piotr/nwg-dock-hyprland /tmp/nwg-dock-hyprland &&
    make -C /tmp/nwg-dock-hyprland get build &&
    sudo make -C /tmp/nwg-dock-hyprland install
}
step "Building nwg-dock-hyprland"
run build_nwg_dock
rm -rf /tmp/nwg-dock-hyprland

build_pamixer() {
    rm -rf /tmp/pamixer &&
    git clone https://github.com/cdemoulins/pamixer.git /tmp/pamixer &&
    meson setup /tmp/pamixer/build /tmp/pamixer &&
    meson compile -C /tmp/pamixer/build &&
    sudo meson install -C /tmp/pamixer/build
}
step "Building pamixer" "Waybar's volume module shells out to this."
run build_pamixer
rm -rf /tmp/pamixer

build_nwg_look() {
    rm -rf /tmp/nwg-look &&
    git clone https://github.com/nwg-piotr/nwg-look /tmp/nwg-look &&
    make -C /tmp/nwg-look build &&
    sudo make -C /tmp/nwg-look install
}
step "Building nwg-look" "GTK theme picker; Hyprland has no settings GUI of its own."
run build_nwg_look
rm -rf /tmp/nwg-look

install_vscode() {
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc &&
    printf '[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n' \
        | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null &&
    sudo dnf install -y code
}
step "Installing VSCode"
run install_vscode

install_font() {
    rm -rf /tmp/0xProto /tmp/0xProto.zip &&
    wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/0xProto.zip -O /tmp/0xProto.zip &&
    unzip -q /tmp/0xProto.zip -d /tmp/0xProto &&
    sudo cp -r /tmp/0xProto /usr/share/fonts/ &&
    sudo fc-cache -f
}
step "Installing the 0xProto Nerd Font"
run install_font
rm -rf /tmp/0xProto /tmp/0xProto.zip

SPOTIFY_DIR=/var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify
install_spotify() {
    flatpak install -y flathub com.spotify.Client || return 1
    curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
    curl -fsSL https://raw.githubusercontent.com/spicetify/marketplace/main/resources/install.sh | sh
    # same story as kitty: spicetify installs to ~/.spicetify, off this shell's PATH
    export PATH="${HOME}/.spicetify:${HOME}/.local/bin:${PATH}"
    spicetify config prefs_path ~/.var/app/com.spotify.Client/config/spotify/prefs &&
    sudo chmod a+wr "$SPOTIFY_DIR" &&
    sudo chmod a+wr -R "$SPOTIFY_DIR/Apps"
}
step "Installing Spotify and Spicetify"
run install_spotify
note "Launch Spotify once, then run: spicetify backup apply"

install_gh() {
    sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo &&
    sudo dnf install -y gh --repo gh-cli
}
step "Installing the GitHub CLI"
run install_gh
note "Authenticate with: gh auth login"

step "Installing Tailscale"
run bash -c 'curl -fsSL https://tailscale.com/install.sh | sh'
note "Join your tailnet with: sudo tailscale up"

step "Installing dark mode theming" "Themes only; GTK and Qt each need to be pointed at them by hand."
run sudo dnf install -y adw-gtk3-theme qt5ct qt6ct kvantum breeze-icons
note "Pick the GTK theme in nwg-look, and the Qt one in qt5ct/qt6ct (style: kvantum)."

install_ec_service() {
    sudo cp "$REPO_DIR/system/ec-charge-limit.service" /etc/systemd/system/ &&
    sudo systemctl enable --now ec-charge-limit.service
}
step "Installing the Framework EC charge limit service" "Caps the battery at 85% to slow wear."
run install_ec_service

step "Linking the configuration" "stow symlinks config/ into ~/.config."
warn "stow will not overwrite real files - if this fails, move the ~/.config"
warn "entries it names out of the way, then re-run: stow -d $REPO_DIR config"
run stow -d "$REPO_DIR" config
hyprctl reload >/dev/null 2>&1 && ok "Hyprland reloaded"

step "Building the Hyprspace overview plugin" "Pins itself to the Hyprspace commit matching your Hyprland version."
if command -v hyprctl >/dev/null && hyprctl version >/dev/null 2>&1; then
    run "$REPO_DIR/install-hyprspace.sh"
else
    warn "no Hyprland session detected - skipped"
    note "Run ./install-hyprspace.sh once you are logged into Hyprland."
fi

note "Log out and select Hyprland from your display manager's session picker."

printf '\n'; rule
if [ ${#FAILED[@]} -eq 0 ]; then
    printf '%s%s✓ All %d steps completed%s %sin %dm%02ds%s\n' \
        "$BOLD" "$GREEN" "$TOTAL" "$RESET" "$DIM" "$(( SECONDS / 60 ))" "$(( SECONDS % 60 ))" "$RESET"
else
    printf '%s%s✗ %d of %d steps failed%s %s(full output: %s)%s\n' \
        "$BOLD" "$RED" "${#FAILED[@]}" "$TOTAL" "$RESET" "$DIM" "$LOG" "$RESET"
    for f in "${FAILED[@]}"; do printf '    %s✗%s %s\n' "$RED" "$RESET" "$f"; done
fi

printf '\n%s%sManual steps left for you%s\n' "$BOLD" "$YELLOW" "$RESET"
i=0
for n in "${NOTES[@]}"; do
    i=$(( i + 1 ))
    printf '  %s%s%d.%s %s\n' "$BOLD" "$YELLOW" "$i" "$RESET" "$n"
done
printf '\n'
