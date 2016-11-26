#!/bin/bash

JOBS=4

TMP=$(mktemp -d)

set -x
find -maxdepth 1 -name "*.zip" -print0 | parallel -0 -j $JOBS "tmp=\$(mktemp -d); unzip -d \$tmp {}; 7za a -t7z -m0=lzma -mx=9 -ms=on {.}.7z \$tmp/*; rm -rf \$tmp"
