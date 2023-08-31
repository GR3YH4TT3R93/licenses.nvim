augroup vimrc
    au!

    au BufEnter * call matchadd('XXX', '\m\C\<XXX\>') 
        \| call matchadd('Fix', '\m\c\<fix\>\|\<fixme\>')
        \| call matchadd('Note', '\m\c\<note\>\|\<info\>')
        \| call matchadd('Todo', '\m\c\<todo\>')

    " terminal
    if has('nvim')
        au BufEnter,TermOpen term://* startinsert
        au TermOpen * setlocal nonumber norelativenumber
    else
        au BufEnter,TerminalOpen term://* startinsert
        au TerminalOpen * setlocal nonumber norelativenumber
    endif
    au BufLeave term:://* stopinsert

    " if a session file loads terminals we might end up in insert mode
    au SessionLoadPost * stopinsert

    " number column
    au BufEnter,FocusGained,InsertLeave,WinEnter *
        \ if &number && mode() != "i"
        \| setlocal relativenumber
        \| endif
    au BufLeave,FocusLost,InsertEnter,WinLeave *
        \ if &number
        \| setlocal norelativenumber
        \| endif
augroup end
