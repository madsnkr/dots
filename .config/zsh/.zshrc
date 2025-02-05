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

# Directory navigation with lf
lfcd () {
    local tmp
    tmp="$(mktemp -uq)"
    trap 'rm -f $tmp >/dev/null 2>&1 && trap - HUP INT QUIT TERM PWR EXIT' HUP INT QUIT TERM PWR EXIT
    lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        local dir
        dir="$(cat "$tmp")"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}
# Change directory to repo after lazygit
lg()
{
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir

    lazygit "$@"

    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
            cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
            rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}
# Function to set the prompt based on vi mode
prompt_set(){
  if [[ $KEYMAP == vicmd ]]; then
      MODE_INDICATOR="[N]"  # Normal mode indicator
  else
      MODE_INDICATOR="[I]"  # Insert mode indicator
  fi

  # Set the prompt with the mode indicator
  NEWLINE=$'\n'
  PROMPT="%~${NEWLINE}(%n@%m)${MODE_INDICATOR}$ "
}

# Trigger prompt update on mode change
zle-keymap-select(){
  prompt_set
  zle reset-prompt
}
zle -N zle-keymap-select

# Initialize the prompt when starting a new line
zle-line-init(){
  prompt_set
  zle reset-prompt
}
zle -N zle-line-init

prompt_set
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
autoload -U select-quoted select-bracketed
zle -N select-quoted && zle -N select-bracketed
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
bindkey -s '^o' '^ulfcd\n' # Lf
bindkey -s '^f' '^ucd "$(dirname "$(fzf)")"\n' # fzf
bindkey -s '^e' '^ufzf --preview="cat {}"|xargs -r nvim\n'
bindkey -s '^g' '^ulg\n' # lazygit

# Syntax highlighting
if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
fi

# Colored prompt
autoload -U colors && colors

