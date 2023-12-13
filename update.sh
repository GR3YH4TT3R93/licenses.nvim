#!/bin/sh

set -ex
cd "$(dirname "${0}")"

./vpm.py sync minimal/plugins.json plugins.json

if [ "$(pwd | sed 's/\/.*\///')" = nvim ]; then
    nvim --headless '+helptags ALL' +TSUpdateSync +q
fi
