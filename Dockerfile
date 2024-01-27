
ARG NEOVIM_RELEASE=${NEOVIM_RELEASE:-https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz}
FROM ubuntu:21.04
ARG NEOVIM_RELEASE

RUN apt-get update
RUN apt-get -y install git curl tar gcc g++ make
RUN mkdir /neovim
RUN curl -sL ${NEOVIM_RELEASE} | tar xzf - --strip-components=1 -C "/neovim"
RUN git clone --depth 1 https://github.com/nvim-lua/plenary.nvim
RUN git clone --depth 1 https://github.com/tjdevries/tree-sitter-lua

WORKDIR tree-sitter-lua
RUN make dist

RUN mkdir /app
WORKDIR /app

ENTRYPOINT ["bash", "-c", "PATH=/neovim/bin:${PATH} VIM=/neovim/share/nvim/runtime nvim --headless -c 'set rtp+=. | set rtp+=../plenary.nvim/ | set rtp+=../tree-sitter-lua/ | runtime! plugin/plenary.vim | luafile ./scripts/gendocs.lua' -c 'qa'"]
