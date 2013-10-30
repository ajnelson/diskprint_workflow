#!/bin/bash

#Environmental assumption: $DIFFER_CONFIG is the user-requested config file

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

#Define Pythons
source "${script_dir}/_pick_pythons.sh"

final_tarball_path="$1"
outfile="$2/sequence_tarballs.txt"

"$PYTHON2" "$script_dir/make_sequence_list.py" --config="$DIFFER_CONFIG" "$final_tarball_path" >"$outfile"
