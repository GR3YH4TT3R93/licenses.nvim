#!/bin/sh

set -ex
cd "$(dirname "${0}")"
./vpm.py -t /usr/bin/nvim sync minimal/plugins.json plugins.json
