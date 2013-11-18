#!/bin/bash

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

#Define Pythons
source "${script_dir}/_pick_pythons.sh"

output_dir="${2}"

fiout="${output_dir}/../make_fiwalk_dfxml_alloc.sh/fiout.dfxml"

"$PYTHON3" "${script_dir}/make_rds_format.py" "$fiout" "${output_dir}/NSRLFile.txt"
