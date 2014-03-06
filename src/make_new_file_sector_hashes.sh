#!/bin/bash

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

#Define Pythons
source "${script_dir}/_pick_pythons.sh"

dwf_output_dir="$2"

input_dfxml="${dwf_output_dir}/../make_differential_dfxml_prior.sh/changes.dfxml"
input_disk_image="${dwf_output_dir}/../invoke_vmdk_to_E01.sh/out.E01"

"$PYTHON3" "${script_dir}/hash_sectors.py" \
  --debug \
  --predicate=newormod \
  --xml="$input_dfxml" \
  "$input_disk_image" \
  "${dwf_output_dir}/sector_hashes.db"
