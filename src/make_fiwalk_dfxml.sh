#!/bin/bash

output_dir=${2}
path_to_e01=${2/%make_fiwalk_dfxml.sh/invoke_vmdk_to_E01.sh}/out.E01
path_to_dfxml=${output_dir}/fiout.dfxml

fiwalk -X"$path_to_dfxml" -f "$path_to_e01"

#Just for the DiskPrints project, check that at least one partition was extracted.
if [ $(grep '<volume ' "$path_to_dfxml" | wc -l) -eq 0 ]; then
  echo "Error: Fiwalk could not extract any partitions from the disk image. This should not be true for Disk Print data.  Exiting with 'No message of desired type' (errno 42)." >&2
  exit 42
fi
