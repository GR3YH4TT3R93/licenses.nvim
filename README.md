# Yet Another ShowMarks Plugin

## Setup

To set up showmarks.vim in VimL you can do either of these:
```vim
let g:showmarks_autoload = 1
```

```vim
call showmarks#setup()
```

And from lua you can:

```lua
vim.g.showmarks_autoload = 1
```

```lua
vim.fn['showmarks#setup']()
```

```lua
require('showmarks').setup()
```

## Docs

TODO

## Reference

* [ShowMarks by exvim](https://github.com/exvim/ex-showmarks)
* [ShowMarks on vim.org](http://www.vim.org/scripts/script.php?script_id=152)
* [ShowMarks on github vim-scripts](https://github.com/vim-scripts/ShowMarks)
* [Easwy's patch](http://easwy.com/blog/archives/advanced-vim-skills-advanced-move-method)

