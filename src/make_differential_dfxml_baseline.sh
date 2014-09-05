#!/bin/bash

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

#Override.
node_id0="${dwf_node_sequence[0]}"
source "${script_dir}/_make_differential_dfxml.sh"
