#!/bin/bash

#Environmental assumption: $DIFFER_CONFIG is the user-requested config file

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

outdir="$2"

#Capture exit status
"${script_dir}/check_tarball_is_sequence_end.py" --debug --config "$DIFFER_CONFIG" "$1"
rc=$?

if [ $rc -eq 0 ]; then
  touch "${outdir}/YES"
else
  touch "${outdir}/NO"
fi

exit $rc
