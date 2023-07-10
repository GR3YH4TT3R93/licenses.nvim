# My personal Neovim config

The `minimal/` directory contains a smaller Vim-compatible config, that I use
on remote machines or setups where I don't need LSP.

Plugins are installed with `vpm.py` based on the contents of `plugins.json` and
`minimal/plugins.json`.

Rest of the config is pretty self-explanatory, just follow the `require` calls
in `init.lua` to find out more.

## Minimal vim setup

_This is here for my convenience, do not blindly copy it_

```bash
git clone https://git.sr.ht/~reggie/config.nvim \
    && cp -f config.nvim/minimal/init.vim ~/.vimrc \
    && mkdir -p ~/.vim \
    && cp -rf config.nvim/* ~/.vim/ \
    && ~/.vim/vpm.py install -d ~/.vim/pack/vpm ~/.vim/minimal/plugins.json
```
