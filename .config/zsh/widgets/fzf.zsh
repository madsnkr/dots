# Searces for text patterns using ripgrep
fzf_search_text() {
  # Set previewer command (bat or fallback to cat)
  local previewer
  previewer=$(command -v bat &> /dev/null && echo 'bat' || echo 'cat')
  local preview_cmd="$previewer -n --color=always {1} --highlight-line {2}"

  # Set rg command
  local grep_cmd
  grep_cmd=$(command -v rg &> /dev/null && \
    echo 'rg --column --line-number --no-heading --color=always --smart-case' || \
    echo 'grep -RIni --color=always --exclude-dir={.git,.obsidian}')

  # Run FZF
	local selected
	selected=$(fzf --ansi --disabled --multi --delimiter ':' \
    --preview="$preview_cmd" \
    --bind "change:reload:[ -n {q} ] && $grep_cmd {q} || printf '';" \
    < /dev/null
  )

  # Exit if nothing was selected
  [ -z "$selected" ] && return

  # Process selection for Neovim
  local -a editor_args
  local first=1

  while IFS= read -r entry; do
    local filename
    local line_num
    filename=$(echo "$entry" | cut -d ':' -f1)
    line_num=$(echo "$entry" | cut -d ':' -f2)

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

# Searches for files using fd or find
fzf_search_files() {
  local find_command
  find_command=$(command -v fd &>/dev/null && echo 'fd --type f --hidden' || echo 'find -type f')

  # Run FZF for file search
  eval "$find_command" | fzf --multi --bind "enter:become($EDITOR -p {+})"
}

zle -N fzf_search_text
zle -N fzf_search_files
