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
    let &undodir=stdpath('state') . '/undo'
else
    silent !mkdir -p ~/.vim/{backup,undo} > /dev/null 2>&1
    let &backupdir=expand('~/.vim/backup')
    let &undodir=expand('~/.vim/undo')
endif
set colorcolumn=80
set completeopt=menu,menuone,noselect,preview
set cursorline
if has('nvim')
    set diffopt+=linematch:60,algorithm:minimal
endif
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
if has('nvim')
    let python3_host_prog = '/usr/bin/python3'
endif
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
set wrapmargin=0
set wildchar=<C-i>

let no_man_maps=v:true

if !has('nvim')
    packloadall
endif

syntax on

runtime minimal/plugins.vim
runtime minimal/keymap.vim
runtime minimal/autocmd.vim
runtime minimal/usercmd.vim
