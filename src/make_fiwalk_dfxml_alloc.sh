#!/bin/bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

dwf_output_dir="$2"
maybe_alloc_only="yes"
source "${script_dir}/_make_fiwalk_dfxml.sh"
