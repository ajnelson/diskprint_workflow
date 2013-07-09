#!/bin/bash

set -e
set -x

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

if [ ! -r "${script_dir}/regxml_extractor.git/deps/bashrc" ]; then
  set +x
  echo "Error: Could not find RegXML Extractor's bashrc file.  Did you run the Git bootstrap script?" >&2
  exit 1
fi

if [ "x$(uname -s)" == "xDarwin" ]; then
  source "${script_dir}/_augment_shell_osx.sh"
fi

cat "${script_dir}/regxml_extractor.git/deps/bashrc" >>~/.bashrc

set +x
echo "Ready to update your shell; run 'source ~/.bashrc' to update your paths." >&2
