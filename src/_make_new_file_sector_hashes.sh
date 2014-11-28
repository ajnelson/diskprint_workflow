#!/bin/bash

echo "DEBUG:_make_new_file_sector_hashes.sh:\$PATH = $PATH"

#Define Pythons
source "${script_dir}/_pick_pythons.sh"

node_id1="$1"
dwf_output_dir="$2"

input_dfxml="${dwf_output_dir}/../make_differential_dfxml_prior.sh/deltas.dfxml"
input_disk_image="${dwf_all_results_root}/by_node/${node_id1}/link_disk.sh/disk0.E01"

"$PYTHON3" "${script_dir}/hash_sectors.py" \
  --debug \
  $pad \
  --predicate=newormod \
  --xml="$input_dfxml" \
  "$input_disk_image" \
  "${dwf_output_dir}/sector_hashes.db"

