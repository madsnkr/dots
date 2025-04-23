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
