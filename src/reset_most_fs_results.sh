#!/bin/bash

# Use this script to blow away all the results except for the ewf conversions (which isn't worth re-doing)
# List targets by passing "ls" as second argument
# Delete targets by passing "rm" as second argument

usage(){
  echo "Usage: $0 results_root {ls|rm}" >&2
}

if [ $# -ne 2 ]; then
  usage
  exit 1
fi

results_root="$1"
if [ ! -d "$results_root" ]; then
  "$0: Error: \$results_root must be a directory: $results_root" >&2
  usage
  exit 1
fi

command=
case $2 in
  ls )
    command="ls -d"
    ;;
  rm )
    command="rm -r"
    ;;
  * )
    usage
    ;;
esac

#Preserving these scripts:
# * invoke_vmdk_to_E01.sh

for x in \
  check_tarball_is_sequence_end.sh \
  do_difference_workflow.sh \
  export_sqlite_to_postgres.sh \
  invoke_regxml_extractor.sh \
  make_differential_dfxml_baseline.sh \
  make_differential_dfxml_prior.sh \
  make_fiwalk_dfxml_all.sh \
  make_fiwalk_dfxml_alloc.sh \
  make_sequence_deltas.sh \
  make_sequence_list.sh \
  run_reg_perl.sh \
  validate_fiwalk_dfxml_all.sh \
  validate_fiwalk_dfxml_alloc.sh \
; do
  find "$results_root" -name "$x" -type d -print0 | \
    while read -d $'\0' y; do
      $command "$y" "$y."{out,err,status}.log
    done
done
