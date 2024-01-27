# Set of mappings to make vim/neovim usable with colemak_dh.

To use this, download it with your plugin manager of choice or just download the
`autoload/colemak_dh.vim` file and place it into your configuration directory.

You should run the setup function before setting up any of your personal
mappings, because they will be overwritten.

If you use Vim you can enable it by setting a variable:
```vim
let g:colemak_dh_autoload=1
```

or running the setup function:

```vim
call colemak_dh#setup()
```

If you use Neovim and Lua, then you can:

```lua
vim.fn['colemak_dh#setup']()
```

or

```lua
require('colemak_dh').setup()
```

There are no customization options, so if you wish to change something feel
free to look at the code (it is very simple) or read
[this](https://ash.fail/20230415-using-vim-with-the-colemak-dh-layout.html)
post.
