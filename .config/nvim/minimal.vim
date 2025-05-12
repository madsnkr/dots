if ! filereadable(stdpath('data') .. '/site/autoload/plug.vim')
	echo "Setting up vim-plug..."
	silent !curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	autocmd VimEnter * PlugInstall
endif

set number relativenumber "Line numbers
set clipboard+=unnamedplus "Use system clipboard
set nohlsearch "Disable search highlighting
set mouse=a "Mouse support for all modes
set tabstop=2 "Number of spaces tabs counts for
set shiftwidth=2 "Number of spaces for indent
set splitbelow splitright "Open splits at bottom and right
filetype plugin indent on "Enable filetype based behavior
syntax on "Enable syntax highlighting

call plug#begin()

Plug 'christoomey/vim-tmux-navigator'
Plug 'pgdouyon/vim-yin-yang'

call plug#end()

colorscheme yin

" Enable transparency
hi Normal guibg=NONE ctermbg=NONE 
hi NormalNC guibg=NONE ctermbg=NONE

let g:zettelkasten_root = expand('~/Zettelkasten')

function! FileJump()
	let l:line = getline('.') " Get text on current line
	let l:col = col('.') - 1 " Get current column number
	let l:pattern = '\[\[\(.\{-}\)\]\]' " Match [[ ... ]]
	let l:start = 0
	let l:link = ''

	" Loop all matches in the line
	while l:start >= 0
		let l:match_pos = matchstrpos(l:line, l:pattern, l:start)

		" Break if no match
		if empty(l:match_pos[0])
			break
		endif

		" Extract match info
		let l:match_text = l:match_pos[0]
		let l:match_start = l:match_pos[1]
		let l:match_end = l:match_pos[2]

		" Check if cursor is inside current match
		if l:col >= l:match_start && l:col <= l:match_end
			let l:link = matchstr(l:match_text, '\[\[\zs.\{-}\ze\]\]') " Extract inner link content
			break
		endif

		" Move search start past current match
		let l:start = l:match_end

	endwhile

	if empty(l:link)
		echo "No link under cursor"
		return
	endif

	" Extract only the filename
	let l:filename = split(l:link, '|')[0]

	" Append .md extension if not present
	if l:filename !~# '\.md$'
		let l:filename .= '.md'
	endif

	let l:filepath = g:zettelkasten_root . "/" . l:filename

	if filereadable(l:filepath)
		execute "edit" fnameescape(l:filepath)
	else
		echo "File not found: " .. l:filepath
	endif

endfunction

augroup FileJumpKeymap
  autocmd!
  autocmd FileType markdown nnoremap <buffer> <CR> :call FileJump()<CR>
augroup END
