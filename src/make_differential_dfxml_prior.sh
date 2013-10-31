#!/bin/bash

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

dwf_output_dir="$2"
source "$script_dir/_results_sequences.sh"

target_dfxml_index=$dwf_tarball_results_dirs_index_previous
source "${script_dir}/_make_differential_dfxml.sh"
