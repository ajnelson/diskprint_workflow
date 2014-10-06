#!/bin/bash

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

#Define Pythons
source "${script_dir}/_pick_pythons.sh"

node_id1="$1"
dwf_output_dir="${2}"

input_disk_image="${dwf_all_results_root}/by_node/${node_id1}/link_disk.sh/disk0.E01"
input_dfxml="${dwf_output_dir}/../make_differential_dfxml_prior.sh/deltas.dfxml"

"$PYTHON3" "${script_dir}/make_rds_format.py" "$input_dfxml" "$input_disk_image" "${dwf_output_dir}/NSRLFile.txt"
