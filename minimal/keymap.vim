noremap <A-e> <Cmd>move .-2<CR>
noremap <A-n> <Cmd>move .+1<CR>
noremap <silent> <Leader>d :Commentary<CR>

inoremap <CR> <Plug>delimitMateCR
inoremap <C-l> <C-g>u<C-u>
inoremap <C-w> <C-g>u<C-w>

nnoremap <silent> <C-i> 
    \:nohlsearch<C-r>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-l>
nnoremap dr% <Plug>(matchup-cs%)
nnoremap sr% <Plug>(matchup-ds%)
nnoremap x% <Plug>(matchup-z%)

onoremap x% <Plug>(matchup-z%)
onoremap u% <Plug>(matchup-i%)

tnoremap <C-e> <Up>
tnoremap <C-n> <Down>
tnoremap <Esc> <C-\><C-N>

vnoremap <silent> <A-e> :move '<-2<CR>gv
vnoremap <silent> <A-n> :move '>+1<CR>gv

xnoremap u% <Plug>(matchup-i%)
xnoremap x% <Plug>(matchup-z%)
