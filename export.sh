#!/bin/bash

rm -rf ./builds/web || true
mkdir -p ./builds/web
cp enable-threads.js ./builds/web/
godot --headless --export-release Web ./builds/web/index.html

cp -r ./builds/web/* ./pages-worktree