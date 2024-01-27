# licenses.nvim

A plugin for easily writing license files and inserting license headers.

<a href="https://asciinema.org/a/587586" target="_blank"><img src="https://asciinema.org/a/587586.svg" /></a>

# Setup

First install the plugin with your package manager of choice. Don't know what
that is? Check out [Paq](https://github.com/savq/paq-nvim).

Inside your init.lua file run the following function:

```lua
require('licenses').setup({
    copyright_holder = 'your name',
    email = 'example@email.com',
    license = 'your license of choice'
})
```

For more configuration options and in depth explanation run
`:help licenses-nvim.Config`.

# Usage

-   LicenseInsert - insert a license on top of your current buffer
-   LicenseFetch - fetch a license from spdx.org
-   LicenseUpdate - update the date in your copyright notice
-   LicenseWrite - write license text to a file

# Documentation

The documentation is in form of a vimdoc file, it contains much more
information than this README, check it out by doing `:help licenses-nvim`.

# Issues

-   issue tracker: https://todo.sr.ht/~reggie/licenses.nvim
-   mailing list: https://lists.sr.ht/~reggie/licenses.nvim
-   contact me directly: https://ash.fail/contact.html
