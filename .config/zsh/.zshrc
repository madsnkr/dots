# History settings
HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/history"
HISTSIZE=1000
SAVEHIST=1000

# Load functions and aliases
source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/functions"
source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliases"

# Zsh options
setopt AUTO_CD
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

stty stop undef # Disable ctrl-s freeze

# Change cursor based on mode
zle-keymap-select(){
  if [[ ${KEYMAP} == vicmd ]]; then
      echo -ne '\e[2 q' # block
    else
      echo -ne  '\e[6 q' # beam
  fi
}
zle -N zle-keymap-select

# Initialize the prompt when starting a new line
zle-line-init(){
  zle -K viins
  echo -ne '\e[6 q'
}
# block cursor when leaving line editor
zle-line-finish() {
  echo -ne '\e[2 q'
}
vi-yank-clipboard() {
  zle vi-yank
  echo "$CUTBUFFER" | wl-copy
}
zle -N zle-line-init
zle -N zle-line-finish
zle -N vi-yank-clipboard

# Completion and bash compatability
autoload -U compinit bashcompinit
zmodload zsh/complist
zstyle ':completion:*' menu select # Add completion selection menu
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump" # Dumpfile under '.cache/zsh'
bashcompinit
_comp_options+=(globdots) # Show hidden files in completion

# Dotnet CLI completion
_dotnet_zsh_complete()
{
  local completions=("$(dotnet complete "$words")")

  # If the completion list is empty, just continue with filename selection
  if [ -z "$completions" ]
  then
    _arguments '*::arguments: _normal'
    return
  fi

  # This is not a variable assignment, don't remove spaces!
  _values = "${(ps:\n:)completions}"
}

compdef _dotnet_zsh_complete dotnet

# Azure CLI completion
[ -f "$HOME/az.completion" ] && source "$HOME/az.completion"

# Vi mode settings
bindkey -v
export KEYTIMEOUT=1
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char
autoload -U select-quoted select-bracketed edit-command-line
zle -N select-quoted
zle -N select-bracketed
zle -N edit-command-line
for m in visual viopp; do
  # ci",ca"..
  for c in {a,i}{\',\",\`}; do
    bindkey -M $m $c select-quoted
  done
  # ci{, ca[ ..
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M $m $c select-bracketed
  done
done

# Keybindings
bindkey -s '^y' '^uy\n' # yazi
bindkey -s '^\' '^ucd "$(dirname "$(fzf --tmux)")"\n' # change directories
bindkey -s '^_' '^ufzf_search "file"\n'
bindkey -s '^t' '^ufzf_search "text"\n'
bindkey -s '^g' '^ulg\n' # lazygit
bindkey -M vicmd '^e' edit-command-line
bindkey -M vicmd 'y' vi-yank-clipboard

# Syntax highlighting
if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
fi

# Colored prompt
autoload -U colors && colors
