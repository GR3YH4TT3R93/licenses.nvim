function! s:DiffWithSaved()
    let filetype=&ft
    diffthis
    vnew | r # | normal! 1Gdd
    diffthis
    exe 'setlocal buftype=nofile bh=wipe nobl noswf ro filetype=' . filetype
endfunction

com! DiffSaved call s:DiffWithSaved()
