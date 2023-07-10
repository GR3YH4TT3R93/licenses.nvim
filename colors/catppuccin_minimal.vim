let s:rosewater='#f2d5cf'
let s:flamingo='#eebebe'
let s:pink='#f4b8e4'
let s:mauve='#ca9ee6'
let s:red='#e78284'
let s:maroon='#ea999c'
let s:peach='#ef9f76'
let s:yellow='#e5c890'
let s:green='#a6d189'
let s:teal='#81c8be'
let s:sky='#99d1db'
let s:sapphire='#85c1dc'
let s:blue='#8caaee'
let s:lavender='#babbf1'

let s:text='#c6d0f5'
let s:subtext1='#b5bfe2'
let s:subtext0='#a5adce'
let s:overlay2='#949cbb'
let s:overlay1='#838ba7'
let s:overlay0='#737994'
let s:surface2='#626880'
let s:surface1='#51576d'
let s:surface0='#414559'

let s:base='#303446'
let s:mantle='#292c3c'
let s:crust='#232634'

let s:none='NONE'

let s:bold = 'bold,'
let s:italic = 'italic,'
let s:undercurl = 'undercurl,'
let s:underline = 'underline,'

hi clear
if exists('syntax_on')
    syntax reset
endif

let g:colors_name='catppuccin'

function! s:hi(group, ...)
    " Arguments: group, guifg, guibg, gui, guisp

    if a:0 >= 1
        let fg = a:1
    else
        let fg = s:none
    endif

    if a:0 >= 2
        let bg = a:2
    else
        let bg = s:none
    endif

    if a:0 >= 3 && strlen(a:3)
        let emstr = a:3
    else
        let emstr = 'NONE,'
    endif

    " let histring = [ 'hi', a:group,
    "     \ 'guifg=' . fg[0], 'ctermfg=' . fg[1],
    "     \ 'guibg=' . bg[0], 'ctermbg=' . bg[1],
    "     \ 'gui=' . emstr[:-2], 'cterm=' . emstr[:-2]
    "     \ ]

    let histring = [
        \'hi', a:group,
        \'guifg=' . fg,
        \'guibg=' . bg, 
        \'gui=' . emstr[:-2], 'cterm=' . emstr[:-2]
    \]

    " special
    if a:0 >= 4
        call add(histring, 'guisp=' . a:4)
    endif

    execute join(histring, ' ')
endfunction

" editor
call s:hi('ColorColumn', s:none, s:surface0)
call s:hi('Conceal', s:overlay1)
call s:hi('CurSearch', s:mantle, s:red)
call s:hi('Cursor', s:base, s:text)
call s:hi('CursorColumn', s:none, s:mantle)
hi link CursorIM Cursor
call s:hi('CursorLine', s:none, '#3b3f52')
call s:hi('CursorLineNr', s:lavender)
call s:hi('Directory', s:blue)
call s:hi('ErrorMsg', s:red, s:none, s:bold . s:italic)
call s:hi('Fix', s:base, s:red)
call s:hi('FloatBorder', s:blue, s:mantle)
call s:hi('FoldColumn', s:overlay0)
call s:hi('Folded', s:blue, s:surface1)
call s:hi('IncSearch', s:mantle, '#8fc1cc')
call s:hi('LineNr', s:surface1)
call s:hi('MatchParen', s:red, s:crust, s:bold)
call s:hi('ModeMsg', s:text, s:none, s:bold)
call s:hi('MoreMsg', s:blue)
call s:hi('MsgSeparator')
call s:hi('NonText', s:overlay0)
call s:hi('Normal', s:text, s:base)
call s:hi('NormalFloat', s:text, s:mantle)
hi link NormalNC Normal
call s:hi('NormalSB', s:text, s:crust)
call s:hi('Pmenu', s:overlay2, '#3b3f52')
call s:hi('PmenuSbar', s:none, s:surface1)
call s:hi('PmenuSel', s:text, s:surface1, s:bold)
call s:hi('PmenuThumb', s:none, s:overlay0)
call s:hi('Question', s:blue)
call s:hi('QuickFixLine', s:none, s:surface1, s:bold)
call s:hi('Search', s:text, '#506373')
call s:hi('SignColumn', s:surface1)
call s:hi('SignColumnSB', s:surface1, s:crust)
call s:hi('SpecialKey', s:text)
call s:hi('SpellBad', s:none, s:none, s:undercurl, s:red)
call s:hi('SpellCap', s:none, s:none, s:undercurl, s:yellow)
call s:hi('SpellLocal', s:none, s:none, s:undercurl, s:blue)
call s:hi('SpellRare', s:none, s:none, s:undercurl, s:green)
call s:hi('StatusLine', s:text, s:mantle)
call s:hi('StatusLineNC', s:surface1, s:mantle)
call s:hi('Substitute', s:pink, s:surface1)
call s:hi('Tabline', s:surface1, s:mantle)
call s:hi('TablineFill')
call s:hi('TablineSel', s:green, s:surface1)
call s:hi('Title', s:blue, s:none, s:bold)
call s:hi('VertSplit', s:crust)
call s:hi('Visual', s:none, s:surface1, s:bold)
hi link VisualNOS Visual
call s:hi('warningMsg', s:yellow)
call s:hi('Whitespace', s:surface1)
call s:hi('WildMenu', s:none, s:overlay0)
call s:hi('WinBar', s:rosewater)
call s:hi('XXX', s:base, s:green)
call s:hi('lCursor', s:base, s:text)

" syntax
call s:hi('Bold', s:none, s:none, s:bold)
call s:hi('Boolean', s:peach)
call s:hi('Character', s:teal)
call s:hi('Comment', s:overlay0, s:none, s:italic)
call s:hi('Conditional', s:mauve, s:none, s:italic)
call s:hi('Constant', s:peach)
hi link Debug Special
hi link Define PreProc
hi link Delimiter Special
call s:hi('DiffAdd', s:none, '#455052')
call s:hi('DiffChange', s:none, '#363c52')
call s:hi('DiffDelete', s:none, '#514251')
call s:hi('DiffText', s:none, '#414964')
call s:hi('Error', s:red)
call s:hi('Float', s:peach)
call s:hi('Function', s:blue)
call s:hi('GlyphPalette1', s:red)
call s:hi('GlyphPalette2', s:teal)
call s:hi('GlyphPalette3', s:yellow)
call s:hi('GlyphPalette4', s:blue)
call s:hi('GlyphPalette6', s:teal)
call s:hi('GlyphPalette7', s:text)
call s:hi('GlyphPalette9', s:red)
call s:hi('Identifier', s:flamingo)
call s:hi('Include', s:mauve)
call s:hi('Italic', s:none, s:none, s:italic)
call s:hi('Keyword', s:mauve)
call s:hi('Label', s:sapphire)
call s:hi('Macro', s:mauve)
call s:hi('Number', s:peach)
call s:hi('Note', s:blue, s:base)
call s:hi('Operator', s:sky)
hi link PreCondit PreProc
call s:hi('PreProc', s:pink)
call s:hi('Repeat', s:mauve)
call s:hi('Special', s:pink)
hi link SpecialChar Special
hi link SpecialComment Special
call s:hi('Statement', s:mauve)
call s:hi('StorageClass', s:yellow)
call s:hi('String', s:green)
call s:hi('Structure', s:yellow)
hi link Tag Special
call s:hi('Todo', s:base, s:yellow, s:bold)
call s:hi('Type', s:yellow)
hi link Typedef Type
call s:hi('Underlined', s:none, s:none, s:underline)
call s:hi('debugBreakpoint', s:base, s:overlay0)
call s:hi('debugPC', s:none, s:crust)
call s:hi('diffAdded', s:green)
call s:hi('diffChanged', s:blue)
call s:hi('diffFile', s:blue)
call s:hi('diffIndexLine', s:teal)
call s:hi('diffLine', s:overlay1)
call s:hi('diffNewFile', s:peach)
call s:hi('diffOldFile', s:yellow)
call s:hi('diffRemoved', s:red)
call s:hi('healthError', s:red)
call s:hi('healthSuccess', s:teal)
call s:hi('healthWarning', s:yellow)
call s:hi('htmlH1', s:pink, s:none, s:bold)
call s:hi('htmlH2', s:blue, s:none, s:bold)
call s:hi('illuminatedCurWord', s:none, s:surface1)
call s:hi('illuminatedWord', s:none, s:surface1)
call s:hi('mkdCodeDelimiter', s:text, s:base)
call s:hi('mkdCodeEnd', s:flamingo, s:none, s:bold)
hi link mkCodeStart mkCodeEnd
call s:hi('qfFileName', s:blue)
call s:hi('qfLineNr', s:yellow)

" vim terminal
let terminal_ansi_colors = [ 
    \s:overlay0, s:red, s:green, s:yellow, s:blue, s:pink, s:sky, s:text,
    \s:overlay1, s:red, s:green, s:yellow, s:blue, s:pink, s:sky, s:text
\]

" nvim terminal
for i in range(0, len(g:terminal_ansi_colors) - 1)
    execute printf("let g:terminal_color_%d='%s'", i, terminal_ansi_colors[i])
endfor
