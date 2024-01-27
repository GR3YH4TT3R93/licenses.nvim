let s:previous_match=''
let s:timer=-1

function! s:cursorword_delete(...) abort
    let s:previous_match=''
    silent! call matchdelete(w:match_id)
endfunction

function! s:cursorword_add_callback(...) abort
    " return if no word character under cursor
    if match(strcharpart(getline('.'), col('.') - 1, 1), '\m\w') == -1
        call s:cursorword_delete()
        return
    endif

    let cword=expand('<cword>')
    if cword ==# s:previous_match
        return
    endif

    call s:cursorword_delete()
    let s:previous_match=cword

    let max_len=get(g:, 'cursorword_max_len', 32)
    if len(cword) != 0 && (max_len == 0 || len(cword) <= max_len)
    let w:match_id=
        \matchadd('CursorWord', '\V\C\<' . escape(cword, '/\') . '\>', -1)
    endif
endfunction

function! s:cursorword_add() abort
    if get(b:, 'cursorword_disable', get(g:, 'cursorword_disable'))
        return
    endif

    let delay=get(g:, 'cursorword_delay', 0)
    if delay == 0
        call s:cursorword_add_callback()
    else
        call timer_stop(s:timer)
        let s:timer=timer_start(delay, 's:cursorword_add_callback')
    endif
endfunction

function! cursorword#setup() abort
    hi default CursorWord cterm=underline gui=underline
    augroup cursorword
        au!
        au BufEnter,CursorMoved,CursorHold * call s:cursorword_add()
        au BufLeave,WinLeave * call s:cursorword_delete()
    augroup end
endfunction
