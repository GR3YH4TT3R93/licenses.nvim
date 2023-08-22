set encoding=utf-8
scriptencoding utf-8

if !exists('g:colors_name')
    colorscheme catppuccin_minimal
endif

set autoindent
set autoread
set backspace=indent,eol,start
set backup
if has('nvim')
    let &backupdir=stdpath('state') . '/backup'
else
    silent !mkdir -p ~/.vim/backup > /dev/null 2>&1
    let &backupdir=expand('~/.vim/backup')
endif
set colorcolumn=80
set cursorline
set display=lastline,truncate
set expandtab
if has('nvim-0.9')
    set exrc
endif
silent! set fillchars+=fold:-,foldopen:┬
silent! set foldcolumn=auto:3
if has('nvim-0.8')
    set foldexpr=nvim_treesitter#foldexpr()
endif
" set 'foldmethod=expr',
set formatoptions+=1j
set fsync
set ignorecase
set incsearch
set list
set listchars=tab:>\ ,trail:_,extends:>,precedes:<,nbsp:+,eol:$
set mouse=a
set mousemodel=extend
set nocompatible
set nolangremap
set notimeout
set nottimeout
set nrformats-=octal
set number
set scrolloff=7
set shiftwidth=4
set sidescrolloff=5
silent! set signcolumn=auto:3-5
set smartcase
set smarttab
set sessionoptions=buffers,curdir,folds,globals,help,tabpages,terminal
set softtabstop=4
set splitbelow
" 'splitkeep=screen', -- not yet better than stabilize.nvim
set splitright
set tabstop=4
if &t_Co == 8
    set t_Co=16
elseif &t_Co > 16
    set termguicolors
endif
set title
set undofile
set updatetime=500
set viewoptions=cursor,folds
set wrapmargin=8
set wildchar=<C-i>

let no_man_maps=v:true

if !has('nvim')
    packloadall
endif

helptags ALL
syntax on

runtime minimal/plugins.vim
runtime minimal/keymap.vim
runtime minimal/autocmd.vim
runtime minimal/usercmd.vim
