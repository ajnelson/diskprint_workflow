#!/bin/bash

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
top_srcdir="${script_dir}/.."

source "${script_dir}/_check.sh"

set -e
set -x

for PYTHON in "$PYTHON2" "$PYTHON3"; do
  $PYTHON "${top_srcdir}/src/differ_library.py" --config="${top_srcdir}/src/differ.cfg" --check --debug
done

set +x
echo "All's well."
echo "Done."
