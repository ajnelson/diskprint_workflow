#!/bin/bash

set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

#Define Pythons
source "${script_dir}/_pick_pythons.sh"

node_id="$1"
dwf_output_dir="$2"

"$PYTHON3" "${script_dir}/fetch_node_data.py" --debug --config="$DIFFER_CONFIG" disk "$node_id" | while read disk_image_path; do
  if [ ! -r "$disk_image_path" ]; then
    echo "ERROR:$(basename $0):Disk image path retrieved from database is not a readable file." >&2
    echo "DEBUG:$(basename $0):disk_image_path = ${disk_image_path}." >&2
    exit 1
  fi
  ln -s "$disk_image_path" "${dwf_output_dir}/"
done

