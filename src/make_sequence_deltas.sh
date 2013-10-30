#!/bin/bash
#Assumed to be run after RegXML Extractor successfully completes.
#Assumes a few directories are present:
# * All the output directories for RegXML Extractor listed in $sequenceoutroot/make_sequence_list.sh/sequence_tarballs.txt
# * $top_src_dir/local/share/regxml_extractor/python - the installed directory of RegXML Extractor's Python code
#Assumes the environment contains:
# * dwf_sequence_id

debug=1

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
$top_src_dir="${script_dir}/.."

#Define Pythons
source "${script_dir}/_pick_pythons.sh"

#(This script doesn't use the tarball path in $1.  That argument is just there for interface consistency with all the other workflow scripts.)

outdir="$2"

if [ -z "$dwf_sequence_id" ]; then
  echo "$0: Error: \$dwf_sequence_id must be defined to call this program." >&2
  exit 1
fi

if [ $debug -eq 0 ]; then
  maybe_debug=
else
  maybe_debug=--debug
fi

pushd "${outdir}" >/dev/null
"$PYTHON3" "${script_dir}/make_sequence_deltas.py" $maybe_debug --with-script-path="${top_src_dir}/local/share/regxml_extractor/python" "$dwf_all_results_root" "$dwf_sequence_id"
status=$?
popd >/dev/null
exit $status
