#!/bin/bash

output_dir="${2}"
path_to_fiwalk_dir="${2/%validate_fiwalk_dfxml.sh/make_fiwalk_dfxml.sh}/"
path_to_dfxml="${path_to_fiwalk_dir}/fiout.dfxml"
path_to_ao_dfxml="${path_to_fiwalk_dir}/fiout-alloc-only.dfxml"

echo "Validating: $path_to_dfxml" >&2
xmllint --noout --schema "${dwf_dfxml_schema}" "${path_to_dfxml}"
echo $? >"${output_dir}/fiout.dfxml.status.log"

echo "Validating: $path_to_ao_dfxml" >&2
xmllint --noout --schema "${dwf_dfxml_schema}" "${path_to_ao_dfxml}"
echo $? >"${output_dir}/fiout-alloc-only.dfxml.status.log"
