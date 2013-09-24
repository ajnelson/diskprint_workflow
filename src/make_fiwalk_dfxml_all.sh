#!/bin/bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

maybe_alloc_only=
source "${script_dir}/_make_fiwalk_dfxml.sh"
