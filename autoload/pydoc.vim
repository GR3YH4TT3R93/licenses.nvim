function! s:read(name) abort
    setlocal keywordprg=:Pydoc
    keepjumps execute 'silent r!python -m pydoc ' . shellescape(a:name)
    Man!
    keepjumps normal! gg
    execute 'file pydoc://' . a:name
endfunction

function! s:pydoc(name) abort
    let bufnr = bufnr('pydoc://' . a:name)
    if !buflisted(bufnr)
        execute 'silent! bwipeout ' . bufnr
        let bufnr = -1
    endif
    let winnr = bufwinnr(bufnr)

    if winnr != -1
        execute winnr . 'wincmd w'
        return
    endif

    " if we don't find exact match look for active pydoc buffers
    let idx = 1
    let wincount = winnr('$')
    while idx <= wincount
        let winbufnr = winbufnr(idx)
        if match(bufname(winbufnr), 'pydoc://.*') == 0
            let winnr = idx
            break
        endif

        let idx += 1
    endwhile

    if winnr == -1
        split
    else
        execute winnr . 'wincmd w'
    endif

    if bufnr == -1
        enew
        call s:read(a:name)
    else
        execute 'buffer ' . bufnr
    endif
endfunction

function! pydoc#setup() abort
    augroup pydoc
        au!
        au BufReadCmd pydoc://*
            \ call s:read(matchstr(expand('<amatch>'), 'pydoc://\zs.*'))
    augroup END

    command! -bar -nargs=1 Pydoc call s:pydoc(<q-args>)
endfunction
