#!/bin/bash

dwf_tarball_results_dirs_sequence_file=test_results_dirs.txt
TESTING_RESULTS_SEQUENCES=yes
dwf_output_dir="/foo bar/0-0-30/test.sh"
source ../src/_results_sequences.sh

echo "Results list: ${dwf_tarball_results_dirs[*]}"
echo "$dwf_tarball_results_dirs_index_end = Ending index"
echo "$dwf_tarball_results_dirs_index_current = Current index"
echo "$dwf_tarball_results_dirs_index_previous = Previous index"
echo "$dwf_tarball_results_dirs_index_next = Next index"
echo "Done."
