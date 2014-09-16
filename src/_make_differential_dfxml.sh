#!/bin/bash

#This script is not meant to be called directly; it should be sourced.

set -e
set -x

#Define Pythons
source "${script_dir}/_pick_pythons.sh"

node_id1="$1"
dwf_output_dir="$2"

#Fetch node_id0
source "${script_dir}/_results_sequences.sh"

if [ $from_baseline -eq 1 ]; then
  node_id0="${dwf_node_sequence[0]}"
fi

target_dfxml="${dwf_all_results_root}/by_node/${node_id0}/make_fiwalk_dfxml_all.sh/fiout.dfxml"
current_dfxml="${dwf_all_results_root}/by_node/${node_id1}/make_fiwalk_dfxml_all.sh/fiout.dfxml"

pushd "${dwf_output_dir}" >/dev/null

#Pretty-print the XML
"$PYTHON3" "$script_dir/make_differential_dfxml.py" \
  --debug \
  "$target_dfxml" \
  "$current_dfxml" \
  >_deltas.dfxml
xmllint --format _deltas.dfxml > deltas.dfxml
rm _deltas.dfxml

popd >/dev/null
