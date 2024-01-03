function! s:Pydoc(name)
    let bufname = 'pydoc://' . a:name
    let bufnr = bufnr(bufname)

    if !buflisted(bufnr)
        execute 'silent! bwipeout ' . bufnr
    endif

    if bufexists(bufnr)
        let winnr = bufwinnr(bufnr)

        if winnr != -1
            execute winnr . 'wincmd w'
        else
            split
            execute 'buffer ' . bufnr
        endif
    else
        new
        execute 'silent r!python -m pydoc ' . shellescape(a:name)
        Man!
        normal! gg
        execute 'file ' . bufname
    endif
endfunction

command! -bar -buffer -nargs=1 Pydoc call s:Pydoc(<q-args>)
setlocal keywordprg=:Pydoc
