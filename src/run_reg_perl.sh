#!/bin/bash

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

output_dir="$2"
path_to_re_out="${output_dir/%run_reg_perl.sh/invoke_regxml_extractor.sh}"

python3.3 "${script_dir}/run_reg_perl.py" --debug "${path_to_re_out}" "${output_dir}"
