# dotfiles

WIP amalgamation of dotfiles vaguely based on Gruvbox.

<img width="2254" height="1502" alt="image" src="https://github.com/user-attachments/assets/7fbcf0b2-0e98-4b9a-901f-940ecebfc290" />


Not finished by any means. Also remind me ~~to add setup scripts and~~ to credit people whose work I've shamelessly adapted and to fix the waybar scripts.

## Installation
1. Clone the repository. 
    ```
    git clone https://github.com/phthallo/dotfiles && cd dotfiles
    ```
2. Run the install script.
    ```
    chmod +x install.sh && ./install.sh
    ```

## Stuff
- Distro: Fedora (setup script was written and intended for Fedora) 
- WM: Hyprland
- Status bar: Waybar
- Dock: nwg-dock-hyprland
- Terminal emulator: Kitty 
- Terminal prompt: Starship
- File manager: Dolphin
- Screenshot: Flameshot
- Shell: zsh
- Launcher: Vicinae
- Browser: Firefox
- Logout: wlogout
- Multimedia key notifications: Avizo
- Spicetify[^1]
- Fastfetch 
- Symlink management: stow 
- Background: Pixel art by [Laced Wing Studio](https://ko-fi.com/lacedwingstudio)

Config files go in `config/.config` (`~/dotfiles/config/.config`).

## Keybinds
- Super + Space for launcher 
- Super + B for browser
- Super + Enter for terminal
- Super + M for Spotify
- Super + Q to close the current program
- Super + S to open special workspace (hyprland default)
- Super + Ctrl + S to add window to special workspace (not hyprland default) 
- Super + Shift + S to screenshot
- Super + F for file manager

[^1]: Make sure to install Spotify using Flatpak.
