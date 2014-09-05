#!/bin/bash

#This script is not meant to be called directly; it should be sourced.

set -e
set -x

#Define Pythons
source "${script_dir}/_pick_pythons.sh"

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
