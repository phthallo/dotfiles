echo "epic dotfiles installer (very experimental)" 
echo "Updating dnf sources"
dnf upgrade --refresh

echo "Enabling external repository sources from Copr" 
sudo dnf copr enable erikreider/SwayNotificationCenter 
sudo dnf copr enable atim/starship 
sudo dnf copr enable rowanfr/fw-ectool

echo "Installing Hyprland"
sudo dnf install hyprland hyprland-devel 

echo "Installing build dependencies and DNF-available packages (stow, starship, fastfetch, wlogout, dolphin, flameshot, waybar, hyprpaper, zsh, vim, blueman)"
sudo dnf install dnf5-plugins make gcc golang glib2-devel cairo-devel cairo-gobject-devel gobject-introspection-devel atk-devel gdk-pixbuf2-devel python3-gobject-devel pango-devel gtk3-devel gtk-layer-shell-devel pulseaudio-libs pulseaudio-libs-devel cxxopts stow starship wlogout dolphin flameshot waybar hyprpaper zsh vim blueman fastfetch SwayNotificationCenter 

chsh -s $(which zsh)

echo "Installing the Meson build system"
python3 -m pip install meson
python3 -m pip install ninja

echo "Installing Vicinae"
curl -fsSL https://vicinae.com/install.sh | bash

echo "Installing and configuring Kitty"
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
kitten themes 'Gruvbox Material Dark Medium'

echo "Installing Avizo"
sudo dnf copr enable tswsl1989/tswsl-wayland-extras 
dnf install avizo 

echo "Cloning and building nwg-dock-hyprland"
git clone github.com/nwg-piotr/nwg-dock-hyprland && cd nwg-dock-hyprland && make get && make build && sudo make install && cd .. && rm -r nwg-dock-hyprland

# echo "Cloning and building keyd"
# git clone https://github.com/rvaiya/keyd
# cd keyd
# make && sudo make install
# sudo systemctl enable --now keyd
# cd .. && rm -r keyd
#

echo "Cloning and building pamixer"
git clone https://github.com/cdemoulins/pamixer.git && cd pamixer
meson setup build
meson compile -C build
meson install -C build
cd ..
rm -r pamixer

echo "Cloning and building nwg-look"
git clone github.com/nwg-piotr/nwg-look 
cd nwg-look && make build && sudo make install
cd .. && rm -r nwg-look


echo "Installing VSCode"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc && echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

dnf check-update && sudo dnf install code

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

echo "Installing Tailscale"
curl -fsSL https://tailscale.com/install.sh | sh

echo "Installing dependencies for dark mode"
sudo dnf install adw-gtk3-theme
sudo dnf install qt5ct qt6ct kvantum kvantum breeze-icons   

echo "Reloading configuration"
stow config && hyprctl reload 

echo "Done! Log out and select Hyprland." 
