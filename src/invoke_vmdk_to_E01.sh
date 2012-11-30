#!/bin/bash

slice_path=${1}
e01_path=${2}/out.E01

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

${script_dir}/vmdk_to_E01.sh "$slice_path" "$e01_path"
