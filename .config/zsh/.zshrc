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

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp" > /dev/null
}

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

fzf_search() {
    # Define common variables
    local mode previewer preview_args selected

    # Parse arguments
    mode="${1:-file}"  # Default to file mode if not specified

    # Set previewer command (bat or fallback to cat)
    previewer=$(command -v bat &> /dev/null && echo 'bat' || echo 'cat')

    # Define common FZF options
    local fzf_common_opts=("--tmux" "80%" "--preview-window=up:60%:wrap:+{2}-/2" '--ansi' '--multi')

    # Handle different search modes
    case "$mode" in
        "text")
            _fzf_search_text "$previewer"
            ;;
        "file")
            _fzf_search_files "$previewer"
            ;;
        *)
            echo "Invalid mode: '$mode'. Use 'text' or 'file'."
            return 1
            ;;
    esac
}

# This function enables multiselect and jump to match for each
_fzf_search_text()
{
	local previewer="$1"
	local rg_cmd="rg --column --line-number --no-heading --color=always --smart-case"
	local preview_cmd="$previewer -n --color=always {1} --highlight-line {2}"

	local selected
	selected=$(fzf ${fzf_common_opts[@]} --disabled --delimiter ':' \
		--preview="$preview_cmd" \
		--bind "change:reload:$rg_cmd {q} || true" < /dev/null)

    # Exit if nothing selected
    [ -z "$selected" ] && return

		# Process selection for Neovim
		local -a editor_args
		local first=1

		while IFS= read -r entry; do
			local filename=$(echo "$entry" | cut -d ':' -f1)
			local line_num=$(echo "$entry" | cut -d ':' -f2)

			if [ "$first" -eq 1 ]; then
				editor_args=("$filename" "+$line_num")
				first=0
			else
				editor_args+=("+tabedit $filename" "+$line_num")
			fi
		done <<< "$selected"

		# Open selected files in Neovim
		nvim "${editor_args[@]}"
}

# Helper function for file search mode
_fzf_search_files() {
    local previewer="$1"
    local preview_cmd="$previewer -n --color=always {}"

    # Run FZF for file search
    fzf ${fzf_common_opts[@]} --preview="$preview_cmd" --bind "enter:become($EDITOR -p {+})"
}

# Keybindings
bindkey -s '^e' '^uy\n' # yazi
bindkey -s '^\' '^ucd "$(dirname "$(fzf --tmux)")"\n' # change directories
bindkey -s '^_' '^ufzf_search "file"\n'
bindkey -s '^t' '^ufzf_search "text"\n'
bindkey -s '^g' '^ulg\n' # lazygit

# Syntax highlighting
if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
fi

# Colored prompt
autoload -U colors && colors
