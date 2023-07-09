augroup filetypedetect
    au BufRead,BufNewFile *.oil,*.ysh set filetype=oil
    au BufRead,BufNewFile *
        \if getline(1) =~ '^#!\(/usr/bin/env \(oil\|ysh\)\|/bin/\(oil\|ysh\)\)'
        \| set filetype=oil
        \| endif
augroup end
