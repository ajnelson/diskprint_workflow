#!/bin/bash

#This script expects these variables:
# * dwf_sequence_id
# * dwf_node_sequence_file (should be defined in do_difference_workflow.sh)
# * node_id1
# * dwf_all_results_root
# * node_id0 (Predecessor to node_id1 in the sequence; blank if no predecessor)

#See "#Definitions" to get the list of variables this module produces.

#This script relaxes some sanity checks if the variable TESTING_RESULTS_SEQUENCES == 'yes'.

#Sanity check variable
INSANE_DIR_COUNT=50

if [ "x$dwf_all_results_root" == "x" ]; then
  echo "ERROR:_results_sequences.sh:Need the variable '\$dwf_all_results_root' to be defined." >&2
  exit 1
fi

if [ ! -d "$dwf_all_results_root" ]; then
  if [ "x$TESTING_RESULTS_SEQUENCES" != "xyes" ]; then
    echo "ERROR:_results_sequences.sh:'\$dwf_all_results_root' ($dwf_all_results_root) is not a directory." >&2
    exit 1
  fi
fi

if [ "x$node_id1" == "x" ]; then
  echo "ERROR:_results_sequences.sh:Need the variable '\$node_id1' to be defined." >&2
  exit 1
fi

if [ "x$dwf_node_sequence_file" == "x" ]; then
  echo "ERROR:_results_sequences.sh:Need the variable '\$dwf_node_sequence_file' to be defined." >&2
  exit 1
fi

if [ ! -r "$dwf_node_sequence_file" ]; then
  echo "ERROR:_results_sequences.sh:'\$dwf_node_sequence_file' ($dwf_node_sequence_file) is not a readable file." >&2
  exit 1
fi


#Definitions
#Note that the _previous and _next indices are kept at this sentinel value if there is no previous or next image in the sequence.
declare -a dwf_node_sequence
declare -a dwf_node_result_sequence
dwf_node_sequence_index=0  #Loop variable
dwf_node_sequence_index_end=-1
dwf_node_sequence_index_current=-1  #Exported variable - current node
dwf_node_sequence_index_previous=-1  #Exported variable - previous node
dwf_node_sequence_index_next=-1
node_id0=  #This remains blank if dwf_node_sequence_index_previous == -1

while read x; do
  dwf_node_sequence[$dwf_node_sequence_index]="${x}"
  dwf_node_result_sequence[$dwf_node_sequence_index]="${dwf_all_results_root}/by_node/${x}"

  #Sanity check: The results directory is actually a directory
  if [ ! -d "${dwf_node_result_sequence[$dwf_node_sequence_index]}" ]; then
    if [ "x$TESTING_RESULTS_SEQUENCES" != "xyes" ]; then
      echo "ERROR:_results_sequences.sh:'$dwf_node_sequence_file' supplied a results directory that is not actually a directory." >&2
      exit 1
    fi
  fi

  #Track the current index, based on the requested output directory.
  #Pattern-matching syntax ref: http://www.cyberciti.biz/faq/bash-find-out-if-variable-contains-substring/
  if [[ $node_id1 = *$x* ]]
  then
    dwf_node_sequence_index_current=$dwf_node_sequence_index
  fi

  dwf_node_sequence_index_end=$dwf_node_sequence_index

  dwf_node_sequence_index=$(expr $dwf_node_sequence_index + 1)

  #Sanity check
  if [ $dwf_node_sequence_index -ge $INSANE_DIR_COUNT ]; then
    echo "ERROR:_results_sequences.sh:Array index has grown to $INSANE_DIR_COUNT.  This is assumed to be an error.  Inspect the contents of '$dwf_node_sequence_file', or relax this check." >&2
    exit 1
  fi
done <"$dwf_node_sequence_file"

if [ $dwf_node_sequence_index_current -ge 0 ]; then
  dwf_node_sequence_index_previous=$(($dwf_node_sequence_index_current - 1))

  dwf_node_sequence_index_next=$(($dwf_node_sequence_index_current + 1))
  if [ $dwf_node_sequence_index_next -gt $dwf_node_sequence_index_end ]; then
    dwf_node_sequence_index_next=-1
  fi
fi

echo "DEBUG:_results_sequences.sh:\$node_id1 = $node_id1" >&2
echo "DEBUG:_results_sequences.sh:\$dwf_node_sequence_index = $dwf_node_sequence_index" >&2
echo "DEBUG:_results_sequences.sh:\$dwf_node_sequence_index_end = $dwf_node_sequence_index_end" >&2
echo "DEBUG:_results_sequences.sh:\$dwf_node_sequence_index_current = $dwf_node_sequence_index_current" >&2
echo "DEBUG:_results_sequences.sh:\$dwf_node_sequence_index_previous = $dwf_node_sequence_index_previous" >&2
echo "DEBUG:_results_sequences.sh:\$dwf_node_sequence_index_next = $dwf_node_sequence_index_next" >&2

if [ $dwf_node_sequence_index_previous -gt -1 ]; then
  node_id0="${dwf_node_sequence[$dwf_node_sequence_index_previous]}"
fi
