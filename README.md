# My personal Neovim config

The `minimal/` directory contains a smaller Vim-compatible config, that I use
on remote machines or setups where I don't need LSP.

Plugins are installed with `update.py` based on the contents of `plugins.json`
and `minimal/plugins.json`.

Rest of the config is pretty self-explanatory, just follow the `require` calls
in `init.lua` to find out more.

## Minimal vim setup

```bash
git clone --depth 1 https://git.ash.fail/config.nvim \
    && mkdir -p ~/.vim \
    && find config.nvim \
        -maxdepth 1 \
        -not -path '*/pack' \
        -not -path '*/.*' \
        -exec cp -rf {} ~/.vim/ \; \
    && ln -sf ~/.vim/minimal/pack ~/.vim/pack \
    && echo "runtime minimal/init.vim" > ~/.vimrc
```
