#!/bin/bash

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

#Define Pythons
source "${script_dir}/_pick_pythons.sh"

dwf_output_dir="${2}"
source "$script_dir/_results_sequences.sh"

#Skip for beginning of sequence (there is no prior for differences)
if [ $dwf_tarball_results_dirs_index_current -eq 0 ]; then
  echo "INFO:$(basename $0):Skipping differential analysis step on baseline image.  (No pre-baseline data in sequence.)" >&2
  exit 0
fi

dfxml="${dwf_output_dir}/../make_differential_dfxml_prior.sh/deltas.dfxml"
diskimage="${dwf_tarball_results_dirs[$dwf_tarball_results_dirs_index_current]}/invoke_vmdk_to_E01.sh/out.E01"

"$PYTHON3" "${script_dir}/make_rds_format.py" "$dfxml" "$diskimage" "${dwf_output_dir}/NSRLFile.txt"
