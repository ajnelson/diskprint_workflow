#!/bin/bash

echo "DEBUG:make_new_file_sector_hashes.sh:\$PATH = $PATH"

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

#Define Pythons
source "${script_dir}/_pick_pythons.sh"

dwf_output_dir="$2"
source "$script_dir/_results_sequences.sh"

input_dfxml="${dwf_output_dir}/../make_differential_dfxml_prior.sh/deltas.dfxml"
input_disk_image="${dwf_tarball_results_dirs[$dwf_tarball_results_dirs_index_current]}/invoke_vmdk_to_E01.sh/out.E01"

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
