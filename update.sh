#!/bin/sh

set -ex
cd "$(dirname "${0}")"
./vpm.py sync minimal/plugins.json plugins.json
