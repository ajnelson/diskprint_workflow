#!/bin/bash

#This script is not meant to be called directly; it should be sourced.
#The variable fiwalk_script_name must be defined by the including script.

if [ -z "$fiwalk_script_name" ]; then
  echo "_validate_fiwalk_dfxml.sh: Error: \$fiwalk_script_name must be defined." >&2
  exit 1
fi

output_dir="${2}"
path_to_dfxml="${output_dir}/../${fiwalk_script_name}/fiout.dfxml"

echo "Validating: $path_to_dfxml" >&2
xmllint --noout --schema "${dwf_dfxml_schema}" "${path_to_dfxml}"
