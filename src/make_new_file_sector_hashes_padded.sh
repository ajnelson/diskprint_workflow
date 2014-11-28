#!/bin/bash

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

pad="--pad"

source "${script_dir}/_make_new_file_sector_hashes.sh"
