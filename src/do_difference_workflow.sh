#!/bin/bash

#This script does the entire differencing workflow for a sequence of disk slice tarballs.  It assumes that at invocation time, the database is updated with diskprint metadata, and the file system has all of the tarballs in place.

#Output for this script is generated as the other output, just in the final tarball's output directory.

#Wrote my own absolute-path dumper on learning that GNU readlink -f doesn't exist in BSD readlink.
my_readlink () {
  #$1 File that exists
  python -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' $1
}

#Document script
script_dirname=$(dirname $(my_readlink $0))
script_basename=$(basename $0)

usage_exit() {
  echo "Usage: $script_basename [options] final_tarball results_root" >&2
  echo "(No options for now.)" >&2
  echo "Places results in \$results_root/\$final_tarball/$script_basename/" >&2
  echo "This script will probably occupy a core for a day.  If you need to restart, blow away the output directory, and execute the SQL in '\$results_root/\$final_tarball/make_sequence_deltas.sh/undo.sql'." >&2
  exit 1
}

if [ $# -lt 2 ]; then
  usage_exit
fi

#Parse input into absolute paths
final_tarball_path=$(my_readlink $1)
results_root_path=$(my_readlink $2)

#Ensure we have an output directory, and change into it
outdir_per_tarball=${results_root_path}${final_tarball_path}
script_outdir=$outdir_per_tarball/$script_basename
mkdir -p "${script_outdir}"
pushd "${script_outdir}" >/dev/null

logandrunscript () {
  #Function arguments:
  # $1: Image  (fimage)
  # $2: Script (fscript)
  # $3...: ?
  #
  #Do initialize the any_errors variable to 0 or whatever integer you want before invoking this function.

  fimage=$1
  fscript=$2
  fscript_basename=$(basename $fscript)
  foutdir=${results_root_path}${fimage}/${fscript_basename}

  #Debug
  printf "Debug: (logandrunscript)\n" >&2
  printf "\t(Local)\n" >&2
  printf "\t\$#=$#\n" >&2
  printf "\t\$fimage=$fimage\n" >&2
  printf "\t\$fscript=$fscript\n" >&2
  printf "\t\$fscript_basename=$fscript_basename\n" >&2
  printf "\t\$foutdir=$foutdir\n" >&2
  printf "\t(Global)\n" >&2
  printf "\t\$@=$@" >&2; printf "\n" >&2 #$@'s null terminated
  printf "\t\$results_root_path=$results_root_path\n" >&2
  printf "\t\$outdir_per_tarball=$outdir_per_tarball\n" >&2
  printf "\t\$any_errors=$any_errors\n" >&2

  if [ -f "$foutdir.status.log" ] && [ "x$(cat $foutdir.status.log)" = "x0" ]; then
    echo "Note: Using previously-created output in \"$foutdir\"." >&2
  else
    #If previously run, don't bother until prior output is out of the way.
    if [ -d "$foutdir" ]; then
      printf "Error: Prior erroneous (or incomplete) output still present.  Inspect and remove manually:\n\t$foutdir\n" >&2
      printf "(You can run this 'rm' to remove the erroneous output and re-run the difference workflow as last called:  'rm -r $foutdir*'.  Run 'ls' first to convince yourself the * resolves correctly, of course.)\n" >&2
      any_errors=$(($any_errors+1))
    else
      mkdir -p "$foutdir"
      "$fscript" "$fimage" "$foutdir" >"$foutdir.out.log" 2>"$foutdir.err.log"
      status=$?
      echo $status>"$foutdir.status.log"
      if [ $status -ne 0 ]; then
        echo "Error: $fscript_basename failed.  See error log \"$foutdir.err.log\" and move or remove the results when the issue is resolved." >&2
        any_errors=$(($any_errors+1))
      fi #Checking exit status
    fi #Checking for prior-not-good output
  fi #Checking for prior-good output
}


#Create the sequence list.
any_errors=0
logandrunscript "$final_tarball_path" "$script_dirname/make_sequence_list.sh"
if [ $any_errors -gt 0 ]; then
  echo "Note: Something went wrong making the sequence list.  Quitting.  See above error log for notes on what went wrong (grep for 'ERROR: ')." >&2
  exit 1
fi
#(This next variable is hard-coded between here and the make_sequence_list.sh script.)
sequence_file=$outdir_per_tarball/make_sequence_list.sh/sequence_tarballs.txt

#Create E01s and RE output directories
any_errors=0
while read sequence_image; do
  echo "Note: Starting E01 processing for \"$sequence_image\"." >&2
  logandrunscript "$sequence_image" "$script_dirname/invoke_vmdk_to_E01.sh"
done<$sequence_file

#Bail out if any errors were found in the loop.
if [ $any_errors -gt 0 ]; then
  echo "Note: Encountered $any_errors errors in the E01 loop.  Quitting.  See above error log for notes on what went wrong (grep for 'ERROR: ')." >&2
  exit 1
fi

#Create Fiwalk DFXML output directories after all E01 output's successfully done
any_errors=0
while read sequence_image; do
  echo "Note: Starting Fiwalk processing for \"$sequence_image\"." >&2
  logandrunscript "$sequence_image" "$script_dirname/make_fiwalk_dfxml.sh"
done<$sequence_file

#Bail out if any errors were found in the loop.
if [ $any_errors -gt 0 ]; then
  echo "Note: Encountered $any_errors errors in the Fiwalk loop.  Quitting.  See above error log for notes on what went wrong (grep for 'ERROR: ')." >&2
  exit 1
fi

#Create RE output directories after all E01 output's successfully done.
#(Creating per-image RE immediately after creating the E01 (and similarly with Fiwalk) means basically trying to integrate Make again: Suddenly, there's a piecemeal, per-tarball dependency graph that has to be defined. A Bash array could probably do it, but recovering from failure becomes tedious right-quick.)
any_errors=0
while read sequence_image; do
  echo "Note: Starting RegXML Extractor processing for \"$sequence_image\"." >&2
  logandrunscript "$sequence_image" "$script_dirname/invoke_regxml_extractor.sh"
done<$sequence_file

#Bail out if any errors were found in the loop.
if [ $any_errors -gt 0 ]; then
  echo "Note: Encountered $any_errors errors in the sequence's individual-processing loop.  Quitting.  See above error log for notes on what went wrong (grep for 'ERROR: ')." >&2
  exit 1
fi

#Translate the successful RE outputs into a sequence
rm -f "${script_outdir}/sequence_res.txt"
while read sequence_image; do
  echo ${results_root_path}${sequence_image}/invoke_regxml_extractor.sh>>"${script_outdir}/sequence_res.txt"
done<$sequence_file

any_errors=0
logandrunscript "$final_tarball_path" "$script_dirname/make_sequence_deltas.sh"
if [ $any_errors -gt 0 ]; then
  echo "Error: Something went wrong aggregating the sequence results into SQLite.  Quitting.  See above error log for notes on what went wrong (grep for 'ERROR: ')." >&2
  exit 1
fi

any_errors=0
logandrunscript "$final_tarball_path" "$script_dirname/export_sqlite_to_postgres.sh"
if [ $any_errors -gt 0 ]; then
  echo "Error: Something went wrong exporting the SQLite to Postgres.  Quitting.  See above error log for notes on what went wrong (grep for 'ERROR: ')." >&2
  echo "Warning: At this point you probably need to delete some records from Postgres.  See the error log for export_sqlite_to_postgres.sh, there are some DELETE statements pre-built." >&2
  exit 1
fi

echo "Done." >&2

popd >/dev/null
