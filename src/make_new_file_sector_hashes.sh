#!/bin/bash

echo "DEBUG:make_new_file_sector_hashes.sh:\$PATH = $PATH"

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

#Define Pythons
source "${script_dir}/_pick_pythons.sh"

node_id1="$1"
dwf_output_dir="$2"

#Skip for beginning of sequence (there is no prior for differences)
if [ $dwf_tarball_results_dirs_index_current -eq 0 ]; then
  echo "INFO:$(basename $0):Skipping differential analysis step on baseline image.  (No pre-baseline data in sequence.)" >&2
  exit 0
fi

input_dfxml="${dwf_output_dir}/../make_differential_dfxml_prior.sh/deltas.dfxml"
input_disk_image="${dwf_all_results_root}/by_node/${node_id1}/link_disk.sh/disk0.E01"

"$PYTHON3" "${script_dir}/hash_sectors.py" \
  --debug \
  --predicate=newormod \
  --xml="$input_dfxml" \
  "$input_disk_image" \
  "${dwf_output_dir}/sector_hashes.db"

"$PYTHON3" "${script_dir}/hash_sectors.py" \
  --debug \
  --pad \
  --predicate=newormod \
  --xml="$input_dfxml" \
  "$input_disk_image" \
  "${dwf_output_dir}/sector_hashes_padded.db"
