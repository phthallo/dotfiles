echo "epic dotfiles installer (very experimental)" 
echo "Updating dnf sources"
dnf upgrade --refresh

echo "Enabling external repository sources from Copr" 
sudo dnf copr enable erikreider/SwayNotificationCenter 
sudo dnf copr enable atim/starship 
sudo dnf copr enable rowanfr/fw-ectool

echo "Installing Hyprland"
sudo dnf install hyprland hyprland-devel 

echo "Installing build dependencies and DNF-available packages (stow, starship, fastfetch, wlogout, dolphin, flameshot, waybar, hyprpaper, zsh, vim)"
sudo dnf install dnf5-plugins make gcc golang glib2-devel cairo-devel cairo-gobject-devel gobject-introspection-devel atk-devel gdk-pixbuf2-devel pango-devel gtk3-devel gtk-layer-shell-devel stow starship wlogout dolphin flameshot waybar hyprpaper zsh vim fastfetch SwayNotificationCenter 

chsh -s $(which zsh)

echo "Installing Vicinae"
curl -fsSL https://vicinae.com/install.sh | bash

echo "Installing and configuring Kitty"
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
kitten themes 'Gruvbox Material Dark Medium'

echo "Cloning and building nwg-dock-hyprland"
git clone github.com/nwg-piotr/nwg-dock-hyprland && cd nwg-dock-hyprland && make get && make build && sudo make install && cd .. && rm -r nwg-dock-hyprland

echo "Installing 0xProto Mono Nerd Font"
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/0xProto.zip \
    && unzip 0xProto.zip -d 0xProto \
    && sudo cp -r 0xProto /usr/share/fonts/ 

rm -r 0xProto.zip 0xProto

echo "Installing Spotify and Spicetify - make sure to configure this after installing"
flatpak install com.spotify.Client \
    && curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh \
    && curl -fsSL https://raw.githubusercontent.com/spicetify/marketplace/main/resources/install.sh | sh \
    && spicetify config prefs_path ~/.var/app/com.spotify.Client/config/spotify/prefs \
    && sudo chmod a+wr /var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify \
    && sudo chmod a+wr -R /var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify/Apps \
    && spicetify backup apply \
    && spicetify apply
  
echo "Installing GH CLI"
sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
sudo dnf install gh --repo gh-cli

echo "Reloading configuration"
stow config && hyprctl reload 

echo "Done! Log out and select Hyprland." 
