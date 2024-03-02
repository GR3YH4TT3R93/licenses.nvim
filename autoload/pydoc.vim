"SPDX-FileCopyrightText: 2024 Ash <contact@ash.fail>
"SPDX-License-Identifier: MIT

"MIT License

" Copyright (c) 2024 Ash contact@ash.fail

"Permission is hereby granted, free of charge, to any person obtaining a copy
"of this software and associated documentation files (the "Software"), to deal
"in the Software without restriction, including without limitation the rights
"to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
"copies of the Software, and to permit persons to whom the Software is
"furnished to do so, subject to the following conditions:

"The above copyright notice and this permission notice (including the next
"paragraph) shall be included in all copies or substantial portions of the
"Software.

"THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
"IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
"FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
"AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
"LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
"OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
"SOFTWARE.

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
    let g:pydoc_setup = 1
    augroup pydoc
        au!
        au BufReadCmd pydoc://*
            \ call s:read(matchstr(expand('<amatch>'), 'pydoc://\zs.*'))
        au FileType python setlocal keywordprg=:Pydoc
    augroup END

    command! -bar -nargs=1 Pydoc call s:pydoc(<q-args>)
endfunction
