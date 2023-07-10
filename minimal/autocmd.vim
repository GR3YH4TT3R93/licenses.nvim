augroup vimrc
    au!

    au BufEnter * call matchadd('XXX', '\<XXX\>') 
        \| call matchadd('Fix', '\c\<fix\>\|\<fixme\>')
        \| call matchadd('Note', '\c\<note\>')
        \| call matchadd('Todo', '\c\<todo\>')

    " terminal
    if has('nvim')
        au BufWinEnter,TermOpen,WinEnter term://* startinsert
        au BufWinEnter,TermOpen,WinEnter term://* 
            \setlocal nonumber norelativenumber
    else
        au BufWinEnter,TerminalOpen,WinEnter term://* startinsert
        au BufWinEnter,TerminalOpen,WinEnter term://* 
            \setlocal nonumber norelativenumber
    endif
    au BufLeave term:://* stopinsert

    " number column
    au BufEnter,FocusGained,InsertLeave,WinEnter * 
        \if &nu && mode() != "i" | set rnu | endif
    au BufLeave,FocusLost,InsertEnter,WinLeave * if &nu | set nornu | endif
augroup end
