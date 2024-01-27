"SPDX-License-Identifier: Unlicense

"This is free and unencumbered software released into the public domain.

"Anyone is free to copy, modify, publish, use, compile, sell, or distribute
"this software, either in source code form or as a compiled binary, for any
"purpose, commercial or non-commercial, and by any means.

"In jurisdictions that recognize copyright laws, the author or authors of this
"software dedicate any and all copyright interest in the software to the public
"domain. We make this dedication for the benefit of the public at large and to
"the detriment of our heirs and successors. We intend this dedication to be an
"overt act of relinquishment in perpetuity of all present and future rights to
"this software under copyright law.

"THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
"IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
"FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
"AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
"ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
"WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

"For more information, please refer to <https://unlicense.org/>

let s:sign_group = 'ShowMarks'
let s:timer = -1

function! s:get_sign(ch) abort
    return 'ShowMarks_' . char2nr(a:ch)
endfunction

function! s:on() abort
    silent! unlet b:showmarks_disable
    call s:showmarks()
endfunction

function! s:off() abort
    let b:showmarks_disable = 1
    call sign_unplace(s:sign_group, { 'buffer': bufnr() })
endfunction

function! s:toggle() abort
    if get(b:, 'showmarks_disable')
        call s:on()
    else
        call s:off()
    endif
endfunction

function! s:showmarks_callback(...) abort
    if index(get(g:, 'showmarks_disabled_buftypes', []), &buftype) >= 0
        return
    endif

    let bufnr = bufnr()

    call sign_unplace(s:sign_group, { 'buffer': bufnr })

    let include =
        \get(b:, 'showmarks_include', get(g:, 'showmarks_include', '')
    \)
    let marklist = extend(
        \getmarklist(bufnr),
        \filter(getmarklist(), { _, v -> v.pos[0] == bufnr })
    \)
    let signs = {}

    for mark in marklist
        let ch = strcharpart(mark.mark, 1, 1)
        let lnum = mark.pos[1]
        let idx = stridx(include, ch)
        let prev_sign = get(signs, lnum, [])

        let hl = ''
        if ch =~# '[a-z]'
            let hl = 'Lower'
        elseif ch =~# '[A-Z]'
            let hl = 'Upper'
        else
            let hl = 'Other'
        endif

        if get(prev_sign, 2, hl) != hl
            let hl = 'Multi'
        endif

        if idx == -1
            continue
        endif

        if empty(prev_sign) || idx < prev_sign[0]
            let signs[lnum] = [idx, ch, hl]
        else
            let signs[lnum][2] = hl
        endif
    endfor

    for [lnum, sign] in items(signs)
        let sign_name = s:get_sign(sign[1])

        execute 'hi link ' . sign_name . ' ShowMarks' . sign[2]
        call sign_place(
            \0,
            \s:sign_group,
            \sign_name,
            \bufnr,
            \{
                \'lnum': lnum,
                \'priority': get(g:,
                    \'showmarks_priority',
                    \get(b:, 'showmarks_priority', 10)
                \)
            \})
    endfor
endfunction

function! s:showmarks() abort
    if get(b:, 'showmarks_disable', get(g:, 'showmarks_disable'))
        return
    endif

    let delay=get(g:, 'showmarks_delay', 500)
    if delay == 0
        call s:showmarks_callback()
    else
        call timer_stop(s:timer)
        let s:timer=timer_start(delay, 's:showmarks_callback')
    endif
endfunction

function! showmarks#setup() abort
    let all_marks = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.'`^<>[]{}()\""
    let g:showmarks_include = get(g:, 'showmarks_include', all_marks)
    let g:showmarks_disabled_buftypes = get(
        \g:, 'showmarks_disabled_buftypes', [ 'help', 'nofile', 'terminal' ]
    \)

    for ch in all_marks
        let sign = s:get_sign(ch)
        call sign_define(sign, { 'text': ch, 'texthl': sign })
    endfor

    command! -bar -nargs=0 ShowMarks :call s:showmarks()

    for cmd in ['Off', 'On', 'Toggle']
        execute 'command! -bar -nargs=0 ShowMarks' . cmd
            \. ' :call s:' . tolower(cmd) . '()'
    endfor

    hi default ShowMarksLower ctermfg=blue cterm=bold guifg=lightblue gui=bold
    hi default ShowMarksUpper ctermfg=blue cterm=bold guifg=lightblue gui=bold
    hi default ShowMarksOther ctermfg=blue cterm=bold guifg=lightblue gui=bold
    hi default ShowMarksMulti ctermfg=blue cterm=bold guifg=lightblue gui=bold
    hi default ShowMarksMulti ctermfg=blue cterm=bold guifg=red gui=bold

    augroup showmarks
        au!
        au BufEnter,CursorHold,CursorMoved,ModeChanged * call s:showmarks()
    augroup end
endfunction
