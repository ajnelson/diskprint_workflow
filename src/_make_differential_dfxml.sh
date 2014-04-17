#!/bin/bash

#This script is not meant to be called directly; it should be sourced.
#The variable target_dfxml_index must be defined by the including script.

if [ -z "$target_dfxml_index" ]; then
  echo "_make_differential_dfxml.sh: Error: \$target_dfxml_index must be defined." >&2
  exit 1
fi

if [ $dwf_tarball_results_dirs_index_previous -eq -1 ]; then
  echo "Note: Skipping generating difference.  No image comes prior to the beginning of the sequence." >&2
  exit 0
fi

set -e
set -x

#Define Pythons
source "${script_dir}/_pick_pythons.sh"

target_dfxml="${dwf_tarball_results_dirs[$target_dfxml_index]}/make_fiwalk_dfxml_all.sh/fiout.dfxml"
current="${dwf_tarball_results_dirs[$dwf_tarball_results_dirs_index_current]}/make_fiwalk_dfxml_all.sh/fiout.dfxml"

pushd "${dwf_output_dir}" >/dev/null

#Pretty-print the XML
"$PYTHON3" "$script_dir/make_differential_dfxml.py" \
  --debug \
  "$target_dfxml" \
  "$current" \
  >_deltas.dfxml
xmllint --format _deltas.dfxml > deltas.dfxml
rm _deltas.dfxml

popd >/dev/null
