#!/bin/bash

#This script expects these variables:
# * dwf_tarball_results_dirs_sequence_file (should be defined in do_difference_workflow.sh)
# * dwf_output_dir
# * dwf_all_results_root
#This script relaxes some sanity checks if the variable TESTING_RESULTS_SEQUENCES == 'yes'.
#See "#Definitions" to get the list of variables this module produces.

#Sanity check variable
INSANE_DIR_COUNT=50

if [ "x$dwf_all_results_root" == "x" ]; then
  echo "Error: _results_sequences.sh: need the variable '\$dwf_all_results_root' to be defined." >&2
  exit 1
fi

if [ ! -d "$dwf_all_results_root" ]; then
  if [ "x$TESTING_RESULTS_SEQUENCES" != "xyes" ]; then
    echo "Error: _results_sequences.sh: '\$dwf_all_results_root' ($dwf_all_results_root) is not a directory." >&2
    exit 1
  fi
fi

if [ "x$dwf_output_dir" == "x" ]; then
  echo "Error: _results_sequences.sh: need the variable '\$dwf_output_dir' to be defined." >&2
  exit 1
fi

if [ ! -d "$dwf_output_dir" ]; then
  if [ "x$TESTING_RESULTS_SEQUENCES" != "xyes" ]; then
    echo "Error: _results_sequences.sh: \$dwf_output_dir' ($dwf_output_dir) is not a directory." >&2
    exit 1
  fi
fi

if [ "x$dwf_tarball_results_dirs_sequence_file" == "x" ]; then
  echo "Error: _results_sequences.sh: need the variable '\$dwf_tarball_results_dirs_sequence_file' to be defined." >&2
  exit 1
fi

if [ ! -r "$dwf_tarball_results_dirs_sequence_file" ]; then
  echo "Error: _results_sequences.sh: '\$dwf_tarball_results_dirs_sequence_file' ($dwf_tarball_results_dirs_sequence_file) is not a readable file." >&2
  exit 1
fi


#Definitions
#Note that the _previous and _next indces are kept at this sentinel value if there is no previous or next image in the sequence.
declare -a dwf_tarball_results_dirs
dwf_tarball_results_dirs_index=0
dwf_tarball_results_dirs_index_end=-1
dwf_tarball_results_dirs_index_current=-1
dwf_tarball_results_dirs_index_previous=-1
dwf_tarball_results_dirs_index_next=-1

while read x; do
  dwf_tarball_results_dirs[$dwf_tarball_results_dirs_index]="${dwf_all_results_root}/slice$x"

  #Sanity check: The results directory is actually a directory
  if [ ! -d "${dwf_tarball_results_dirs[$dwf_tarball_results_dirs_index]}" ]; then
    if [ "x$TESTING_RESULTS_SEQUENCES" != "xyes" ]; then
      echo "Error: _results_sequences.sh: '$dwf_tarball_results_dirs_sequence_file' supplied a results directory that is not actually a directory." >&2
      exit 1
    fi
  fi

  #Track the current index
  #Pattern-matching syntax ref: http://www.cyberciti.biz/faq/bash-find-out-if-variable-contains-substring/
  if [[ $dwf_output_dir = *$x* ]]
  then
    dwf_tarball_results_dirs_index_current=$dwf_tarball_results_dirs_index
  fi

  dwf_tarball_results_dirs_index_end=$dwf_tarball_results_dirs_index

  dwf_tarball_results_dirs_index=$(expr $dwf_tarball_results_dirs_index + 1)

  #Sanity check
  if [ $dwf_tarball_results_dirs_index -ge $INSANE_DIR_COUNT ]; then
    echo "Error: _results_sequences.sh: array index has grown to $INSANE_DIR_COUNT.  This is assumed to be an error.  Inspect the contents of '$dwf_tarball_results_dirs_sequence_file', or relax this check." >&2
    exit 1
  fi
done <"$dwf_tarball_results_dirs_sequence_file"

if [ $dwf_tarball_results_dirs_index_current -ge 0 ]; then
  dwf_tarball_results_dirs_index_previous=$(expr $dwf_tarball_results_dirs_index_current - 1);

  dwf_tarball_results_dirs_index_next=$(expr $dwf_tarball_results_dirs_index_current + 1);
  if [ $dwf_tarball_results_dirs_index_next -gt $dwf_tarball_results_dirs_index_end ]; then
    dwf_tarball_results_dirs_index_next=-1
  fi
fi
