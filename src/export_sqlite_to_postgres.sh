#!/bin/bash

#Environmental assumption: $DIFFER_CONFIG is the user-requested config file

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

#Define Pythons
source "${script_dir}/_pick_pythons.sh"

outdir="$2"

"$PYTHON2" "${script_dir}/export_sqlite_to_postgres.py" --debug --config="$DIFFER_CONFIG" "$dwf_sequence_id" "${outdir}/../make_sequence_deltas.sh/registry_deltas.db"
