#!/bin/bash

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

set -e

#Define Pythons
source "${script_dir}/_pick_pythons.sh"

output_dir="${2}"

rdsout="${output_dir}/../make_rds_format.sh/NSRLFile.txt"

"$PYTHON2" "${script_dir}/cyboxFileObj.py" "$rdsout" > "${output_dir}/FileObjs.xml"
