#!/bin/bash

#Assumes the environment contains:
# * dwf_sequence_id

#Environmental assumption: $DIFFER_CONFIG is the user-requested config file

debug=1

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

#Define Pythons
source "${script_dir}/_pick_pythons.sh"

final_tarball_path="$1"
outfile="$2/sequence_nodes.txt"

if [ $debug -eq 0 ]; then
  maybe_debug=
else
  maybe_debug=--debug
fi

"$PYTHON2" "$script_dir/lineage_librarian.py" $maybe_debug --config="$DIFFER_CONFIG" >"$outfile"
