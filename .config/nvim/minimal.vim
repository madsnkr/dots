if ! filereadable(stdpath('data') . '/site/autoload/plug.vim')
	echo "Setting up vim-plug..."
	silent !curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	autocmd VimEnter * PlugInstall
endif

let mapleader = " "

set number relativenumber "Line numbers
set clipboard+=unnamedplus "Use system clipboard
set formatoptions-=cro " Disable comment continuation
set ic " Case insensitive search
set nohlsearch "Disable search highlighting
set mouse=a "Mouse support for all modes
set tabstop=2 "Number of spaces tabs counts for
set shiftwidth=2 "Number of spaces for indent
set splitbelow splitright "Open splits at bottom and right
filetype plugin indent on "Enable filetype based behavior
syntax on "Enable syntax highlighting

call plug#begin()

Plug 'christoomey/vim-tmux-navigator'

call plug#end()

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
	
	" Construct filepath based on filename pattern
	if l:filename =~ '^/' " prefix '/'
		let l:filepath = simplify(g:zettelkasten_root . l:filename)
	elseif l:filename =~ '^\.\{1,2}/' " prefix './' or '../'
		let l:filepath = simplify(expand('%:p:h') . '/' . l:filename)
	else
		let l:filepath = glob(g:zettelkasten_root . '/**/' . l:filename) " search recursively

		if l:filepath == ''
			let l:filepath = simplify(g:zettelkasten_root . '/' . l:filename) " default to root
		endif
	endif

	if !filereadable(l:filepath)
		echo "Opened new file:" l:filepath
	endif

	execute "edit" fnameescape(l:filepath)

endfunction

function! FileRename()
	" Get current filepath and bufnr
	let l:current = expand('%:p')
	let l:buf = bufnr('%')

	" Prompt for user input
	call inputsave()
	let l:new = input("Enter new name: ", l:current, "filetype")
	call inputrestore()

	if l:new == '' || l:new == l:current
		return
	endif

	call rename(l:current, l:new)

	" Update buffer filepath
	execute "file " . fnameescape(l:new)

	let l:oldname = expand('#:t:r') 
	let l:newname = expand('%:t:r')

	" Populate the qflist with link matches
	call PopulateMatches(l:oldname)

	let l:qf_size = len(getqflist())

	let l:pattern = '\[\[\([\w\s./]*/\)\=' . l:oldname . '\(|[^\]]*\)\=\]\]'
	let l:replacement = '[[\1' . l:newname . '\2]]'

	silent execute 'cfdo %s@' . l:pattern . '@' . l:replacement . '@g | update'

	echo "Updated " . l:qf_size . " file(s)"

	" Jump back to the file
	execute 'buffer' l:buf

endfunction

function! PopulateMatches(name)

	let l:pattern = '\[\[([\w\s./]*/)?' . a:name . '(\\|[^\]]*)?\]\]'

	let l:cmd = "grep! -g '!**/{.git,.obsidian}/*' " . shellescape(l:pattern) . " " . shellescape(g:zettelkasten_root)

	silent execute l:cmd

endfunction

function! BackLinks()
	" If quickfix window is open, just close it and exit
	if !empty(filter(getwininfo(), 'v:val.quickfix'))
		cclose
		return
	endif

	let l:name = expand('%:t:r') 

	call PopulateMatches(l:name)

	copen

endfunction

augroup FileJumpKeymap
  autocmd!
  autocmd FileType markdown nnoremap <buffer> <CR> :call FileJump()<CR>
augroup END

map <Leader>zb :call BackLinks()<CR>
map <Leader>fr :call FileRename()<CR>
