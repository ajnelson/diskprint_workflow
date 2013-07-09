#!/bin/bash
#Assumed to be run after RegXML Extractor successfully completes.
#Assumes a few directories are present:
# * $outdir/../do_difference_workflow.sh
# * All the output directories for RegXML Extractor listed in $imageoutroot/make_sequence_list.sh/sequence_tarballs.sh
# * ~/local/share/regxml_extractor/python - the installed directory of RegXML Extractor

debug=1

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

final_tarball_path="$1"
outdir="$2"
sequence_res="${outdir/%make_sequence_deltas.sh/do_difference_workflow.sh}/sequence_res.txt"

if [ $debug -eq 0 ]; then
  maybe_debug=
else
  maybe_debug=--debug
fi

pushd "${outdir}" >/dev/null
"${script_dir}/make_sequence_deltas.py" $maybe_debug --with-script-path="$HOME/local/share/regxml_extractor/python" "${final_tarball_path}" "${sequence_res}"
status=$?
popd >/dev/null
exit $status
