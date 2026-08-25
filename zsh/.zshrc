# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename "$HOME/.zshrc"

autoload -Uz compinit
compinit
# End of lines added by compinstall

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(git zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh

alias spotify="flatpak run com.spotify.Client"

eval "$(starship init zsh)"
fastfetch

export PATH=$PATH:$HOME/.spicetify

# Add ~/.local/bin to PATH
if [ -d "${HOME}/.local/bin" ] && [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
    PATH="${HOME}/.local/bin:${PATH}"
fi

# Add ~/bin to PATH. RubyGems installs gem executables here
# (`gem env` -> EXECUTABLE DIRECTORY), so without this every `gem install`
# lands a binary that nothing on the PATH can find.
if [ -d "${HOME}/bin" ] && [[ ":${PATH}:" != *":${HOME}/bin:"* ]]; then
    PATH="${HOME}/bin:${PATH}"
fi

# bun completions
[ -s "${HOME}/.bun/_bun" ] && source "${HOME}/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"

# pnpm
export PNPM_HOME="${HOME}/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
