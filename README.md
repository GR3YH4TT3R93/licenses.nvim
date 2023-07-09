# My personal Neovim config

The `minimal/` directory contains a smaller Vim-compatible config, that I use
on remote machines or setups where I don't need LSP.

Plugins are installed with `vpm.py` based on the contents of `plugins.json` and
`minimal/plugins.json`.

Rest of the config is pretty self-explanatory, just follow the `require` calls
in `init.lua` to find out more.
