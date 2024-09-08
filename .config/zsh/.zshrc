# History settings
HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/history"
HISTSIZE=1000
SAVEHIST=1000

# Load functions and aliases
source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/functions"
source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliases"

# Zsh options
setopt -Jhg     # Autocd, ignore space and dups
stty stop undef # Disable ctrl-s freeze

# Change cursor shape for different vi modes.
function zle-keymap-select () {
    case $KEYMAP in
        vicmd) echo -ne '\e[1 q';;      # block
        viins|main) echo -ne '\e[5 q';; # beam
    esac
}
zle -N zle-keymap-select
zle-line-init() { echo -ne "\e[5 q"; }
zle -N zle-line-init

preexec() { echo -ne '\e[5 q'; } # Reset to beam for new prompt
echo -ne '\e[5 q' # Use beam as initial cursor

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
bindkey -s '^a' '^ubc -lq\n' # bc
bindkey -s '^f' '^ucd "$(dirname "$(fzf)")"\n' # fzf
bindkey -s '^g' '^ulg\n' # lazygit

# Syntax highlighting
if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
fi

# Colored prompt
autoload -U colors && colors
PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "
