#!/bin/bash

#This script does the entire differencing workflow for a sequence of disk slice tarballs.  It assumes that at invocation time, the database is updated with diskprint metadata, and the file system has all of the tarballs in place.

#Output for this script is generated as the other output, just in the final tarball's output directory.

#Include PATH extensions
this_script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
source "$this_script_dir/../_env_extra.sh"

#Propagate SIGINT to subshells: http://stackoverflow.com/a/8366378/1207160
trap "kill 0" SIGINT SIGTERM

#Wrote my own absolute-path dumper on learning that GNU readlink -f doesn't exist in BSD readlink.
my_readlink () {
  #$1 File that exists
  python -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$1"
}

#Document script
script_dirname="$(dirname $(my_readlink $0))"
script_basename=$(basename "$0")

usage="Usage: $script_basename [options] (--parallel-all OR final_tarball) results_root\n"
usage=$usage"Options:\n"
usage=$usage"\t--cleanup {check (default), erase, list, ignore}\n"
usage=$usage"\t  Handle erroneous results found under results_root: Check for any and prompt, erase without prompt, list and exit, or ignore.\n"
usage=$usage"\t--config differ.cfg\n"
usage=$usage"\t  Configuration file for connecting to database.\n"
usage=$usage"\t-h, --help\n"
usage=$usage"\t  Print this help and quit.\n"
usage=$usage"\t-j N, --jobs N\n"
usage=$usage"\t  When doing parallel work, run this many jobs simultaneously.  '0' runs as many as possible.  No effect if --parallel-all is not passed.\n"
usage=$usage"\t--parallel-all\n"
usage=$usage"\t  Run workflow in parallel on all disk images stored in database 'storage' table.\n"
usage=$usage"\t--quiet\n"
usage=$usage"\t  Redirect _most_ stdout and stderr output to /dev/null.  Exceptions noted in this help.\n"
usage=$usage"\t--re-export\n"
usage=$usage"\t  Re-run export step for specified sequence(s).\n"
usage=$usage"\t--report-pidlog\n"
usage=$usage"\t  Output a line of text that notes where this workflow instance's log is stored.  Ignores --quiet.\n"
usage=$usage"Places results in \$results_root/\$final_tarball/$script_basename/\n"
usage=$usage"This script will probably occupy a core for a day.  If there are database errors, the relevant scripts' .err.log files will include SQL 'undo' statements.\n"

usage_exit() {
  printf "$usage" >&2
  exit 1
}

#Set defaults
GNU_GETOPT=/opt/local/bin/getopt
DIFFER_CONFIG="${script_dirname}/differ.cfg"
cleanup=check
num_jobs=0
parallel_all=0
quiet=0
re_export=0
report_pidlog=0

if ! options=$(${GNU_GETOPT} -o hj: -l cleanup:,config:,help,jobs:,parallel-all,quiet,re-export,report-pidlog -- "$@"); then
  # Something went wrong; getopt should report what.
  exit 1
fi
eval set -- "$options"

while [ $# -ge 1 ]; do
  case $1 in
    --cleanup )
      case $2 in
        check | erase | list | ignore )
          cleanup=$2
          shift
          ;;
        * )
          echo "Error: $script_basename: --cleanup parameter must be 'check', 'erase', 'list', or 'ignore'.  Instead got '$2'." >&2
          usage_exit
          ;;
      esac
      ;;
    --config )
      DIFFER_CONFIG="$2"
      shift
      ;;
    -h | --help )
      printf "$usage"
      exit 0
      ;;
    -j | --jobs )
      #"[[" example c/o http://stackoverflow.com/a/2210386
      if [[ ! $2 =~ ^[0-9]+$ ]]; then
        echo "Error: $script_basename: $1 parameter must be a non-negative integer.  Instead got '$2'." >&2
        usage_exit
      fi
      num_jobs=$2
      shift
      ;;
    --parallel-all )
      parallel_all=1
      PARALLEL="$(which parallel)"
      if [ ! -x "$PARALLEL" ]; then
        echo "Error: GNU Parallel not found.  '$1' cannot be passed to this script without parallel executable." >&2
        exit 1
      fi
      ;;
    --quiet )
      quiet=1
      ;;
    --re-export )
      re_export=1
      ;;
    --report-pidlog )
      report_pidlog=1
      ;;
    -- )
      shift
      break
      ;;
    * )
      break
      ;;
  esac
  shift
done

#Code smell: GNU parallel's --quote flag does a good job of quoting variables, but when interacting with GNU getopt, causes multiple-whitespace strings to be interprted as blank arguments.  This simple loop lops off the blank head arguments.
while [ -z "$1" ]; do
  shift
done

#Check argument counts and parse into absolute paths
results_root_path=
if [ $parallel_all -eq 1 ]; then
  if [ $# -ne 1 ]; then
    echo "ERROR:${script_basename}:Expecting 1 argument. Got $#." >&2
    echo "DEBUG:${script_basename}:\$@ = $@" >&2
    usage_exit
  fi
  results_root_path="$(my_readlink "$1")"
else
  if [ $# -ne 2 ]; then
    echo "ERROR:${script_basename}:Expecting 2 arguments. Got $#." >&2
    echo "ERROR:${script_basename}:\$@ = $@" >&2
    usage_exit
  fi
  results_root_path="$(my_readlink "$2")"
fi

if [ ! -r "$DIFFER_CONFIG" ]; then
  echo "ERROR:${script_basename}:Config file not readable: $DIFFER_CONFIG" >&2
  exit 1
fi
export dwf_all_results_root="$results_root_path"
export DIFFER_CONFIG="$(my_readlink $DIFFER_CONFIG)"
#echo "Debug: $script_basename: \$DIFFER_CONFIG = $DIFFER_CONFIG" >&2

export dwf_dfxml_schema="$script_dirname/../deps/dfxml_schema.git/dfxml.xsd"
#echo "DEBUG:${script_basename}:\$dwf_dfxml_schema = $dwf_dfxml_schema" >&2

#Call this function to list all of the directories and logs of scripts with erroneous output under the results root path
#Pass --null-delimit as first arg to cause `find` to output with -print0, unsorted.
find_errors() {
  #Refs for reading paths with spaces in the name:
  #* http://stackoverflow.com/a/11366230/1207160
  #* http://www.cyberciti.biz/tips/handling-filenames-with-spaces-in-bash.html
  find "$dwf_all_results_root" -name '*.sh.status.log' -print0 | \
    while read -d $'\0' x; do
      if [ $(egrep -v '^0$' "$x" | wc -l) -gt 0 ]; then
        xbn="$(basename "$x")"
        xdn="$(dirname "$x")"
        if [ -z "$1" ]; then
          find "$xdn" -name "${xbn/%.status.log/}*" | sort
        elif [ "x$1" == "x--null-delimit" ]; then
          find "$xdn" -name "${xbn/%.status.log/}*" -print0
        fi
      fi
    done
}

#Maybe check for erroneous results
if [ "x$cleanup" == "xcheck" ]; then
  echo "DEBUG:${script_basename}:Scanning for prior erroneous results." >&2
  #Count the number of directories (using status logs as proxy)
  error_tally=$(find_errors | grep '.sh.status.log' | wc -l)
  if [ $error_tally -eq 0 ]; then
    echo "DEBUG:${script_basename}:None found." >&2
  else
    echo "NOTE:${script_basename}:Found prior erroneous results ($error_tally directories)." >&2
    while true; do
      read -e -p "Remove prior erroneous results? [yes/no/list/abort]: " ynl
      case $ynl in
        [Yy]* )
          echo "NOTE:${script_basename}:Erasing prior erroneous results." >&2
          find_errors --null-delimit | xargs -0 rm -r
          break
          ;;
        [Nn]* )
          break
          ;;
        [Aa]* )
          echo "NOTE:${script_basename}:Exiting." >&2
          exit 0
          ;;
        list )
          echo "These files and directories will be deleted if you remove erroneous results:"
          find_errors
          ;;
        * )
          echo "ERROR:${script_basename}:Unrecognized option. Aborting." >&2
          break
          ;;
      esac
    done
  fi
elif [ "x$cleanup" == "xlist" ]; then
  find_errors
  exit 0
elif [ "x$cleanup" == "xerase" ]; then
  find_errors --null-delimit | xargs -0 rm -r
fi

#Check for parallel-invocation mode
if [ $parallel_all -eq 1 ]; then
  echo "NOTE:${script_basename}:Re-running self in parallel." >&2
  #Propagate some arguments
  parg_re_export=
  if [ $re_export -eq 1 ]; then
    parg_re_export="--re-export"
  fi
  parg_report_pidlog=
  if [ $report_pidlog -eq 1 ]; then
    parg_report_pidlog="--report-pidlog"
  fi
  ./sliceprocessor.py --config "$DIFFER_CONFIG" | \
    parallel --quote -j1 \
      "$0" "$parg_report_pidlog" "$parg_re_export" --cleanup ignore -j $num_jobs --config "$DIFFER_CONFIG" --quiet {} "$@"
  exit 0
fi

#The rest of this script is single-slice/single-sequence mode.

#Pick Pythons
source "${this_script_dir}/_pick_pythons.sh"
dwf_sequence_id="$1"
echo "DEBUG:${script_basename}:\$dwf_sequence_id = $dwf_sequence_id" >&2
export dwf_sequence_id
outdir_per_sequence="${results_root_path}/by_graph/${dwf_sequence_id}"

#Ensure we have an output directory
workflow_script_outdir="${outdir_per_sequence}/${script_basename}"

#Set up logging
mkdir -p "${workflow_script_outdir}" || exit 1
script_out_log="${workflow_script_outdir}.out.log"
script_err_log="${workflow_script_outdir}.err.log"
script_status_log="${workflow_script_outdir}.status.log"

#Clear old logs
rm -f \
  "$script_out_log" \
  "$script_err_log" \
  "$script_status_log"

#Log the script exiting from here forward
#Light Bash docs on signal trapping: http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html
#Another helpful page: http://phaq.phunsites.net/2010/11/22/trap-errors-exit-codes-and-line-numbers-within-a-bash-script/
function exit_trap() {
  _LINENO=$1
  _RC=$2
  if [ $_RC -eq 0 ]; then
    echo "Done." >&2
  else
    echo "ERROR:$script_basename:Script process $$ exiting unsuccessfully from line $_LINENO, exit status $_RC." >&2
    echo $_RC >"$script_status_log"
  fi
  exit $_RC
}
trap 'exit_trap ${LINENO} $?' EXIT

#Log stdout and stderr from this point on
#Light Bash docs on redirecting current script's std*: http://tldp.org/LDP/abs/html/x17891.html
if [ $report_pidlog -eq 1 ]; then
  echo "DEBUG:$script_basename:Stdout and stderr of process $$ redirecting to ${workflow_script_outdir}.{out,err}.log." >&2
fi
#Maybe preserve stdin and stdout
if [ $quiet -eq 1 ]; then
  exec 6>/dev/null
  exec 7>/dev/null
else
  exec 6>&1
  exec 7>&2
fi
#Log stderr and stdout to separated logs
#(In-order logs as well seemed to be problematic)
exec 1> >(tee -a "$script_out_log" >&6)
exec 2> >(tee -a "$script_err_log" >&7)

#Change into the output directory
pushd "${workflow_script_outdir}" >/dev/null

#Trigger exporting results to database by removing last export's output, if present
if [ $re_export -eq 1 ]; then
  if [ $(find "$outdir_per_sequence" -type d -name 'export_sqlite_to_postgres.sh' | wc -l) -gt 0 ]; then
    echo "DEBUG:$script_basename:Removing these directories and files." >&2
    find "$outdir_per_sequence" -type d -name 'export_sqlite_to_postgres.sh' -print0 | xargs -0 ls -d
    find "$outdir_per_sequence" -type d -name 'export_sqlite_to_postgres.sh' -print0 | xargs -0 rm -r
    find "$outdir_per_sequence" -type f -name 'export_sqlite_to_postgres.sh.*.log' -print0 | xargs -0 ls
    find "$outdir_per_sequence" -type f -name 'export_sqlite_to_postgres.sh.*.log' -print0 | xargs -0 rm
  fi
fi

logandrunscript () {
  #This function creates the script's output directory, and several log files alongside the directory: stdout, stderr, and exit status.
  #This function checks for an exit status log, and if it finds one that reports a previous run was successful, it just exits saying work has been successfully done.  NB: If a previous script in the sequence has had its results updated, you should delete all of the output it affects (a very, very broad taint analysis).
  #Function arguments:
  # $1: Whether this is a node-, edge-, or graph-level analysis (node|edge|graph)
  # $2: Script basename (fscript)
  # $3: Input ID (node id, end node id of an edge, or graph ID)

  analysis_type="$1"

  fscript="$2"
  fscript_basename="$(basename $fscript)"

  target_id="$3"

  if [ -z "$target_id" ]; then
    echo "ERROR:$0:logandrunscript called without a target ID." >&2
    exit 1
  fi

  if [ "$analysis_type" == "node" ]; then
    node_id0="$3"
    foutdir="${dwf_all_results_root}/by_node/${node_id0}/${fscript_basename}"
  elif [ "$analysis_type" == "edge" ]; then
    node_id1="$3"

    source "${script_dirname}/_results_sequences.sh"
    if [ -z "${node_id0}" ]; then
      #This script was called for the baseline of the sequence.  There is no differencing to be done.
      return 0
    fi

    foutdir="${dwf_all_results_root}/by_edge/${node_id0}/${node_id1}/${fscript_basename}"
  elif [ "$analysis_type" == "graph" ]; then
    foutdir="${dwf_all_results_root}/by_graph/${dwf_sequence_id}/${fscript_basename}"
  else
    "ERROR:${script_basename}:logandrunscript called without a proper analysis type argument." >&2
    exit 1
  fi

  #Debug
  printf "DEBUG:${script_basename}:(logandrunscript)\n" >&2
  printf "\t(Local)\n" >&2
  printf "\t\$#=$#\n" >&2
  printf "\t\$fscript=$fscript\n" >&2
  printf "\t\$foutdir=$foutdir\n" >&2
  printf "\t(Global)\n" >&2
  printf "\t\$@=$@" >&2; printf "\n" >&2 #$@'s null terminated
  printf "\t\$dwf_all_results_root=$dwf_all_results_root\n" >&2

  if [ -f "$foutdir.status.log" ] && [ "x$(cat "$foutdir.status.log")" == "x0" ]; then
    echo "Note: Using previously-created output in \"$foutdir\"." >&2
  else
    #If previously run, don't bother until prior output is out of the way.
    if [ -d "$foutdir" ]; then
      printf "ERROR:${script_basename}:Prior erroneous (or incomplete) output still present.  Please inspect:\n\t$foutdir\nand\n\t$foutdir.*.log\n" >&2
      printf "(Running the difference workflow again will give you a prompt to remove this and all other erroneous output; see the --cleanup flag for options.)\n" >&2
    else
      mkdir -p "$foutdir"
      echo "Started." >"$foutdir.status.log"
      "$fscript" "$target_id" "$foutdir" >"$foutdir.out.log" 2>"$foutdir.err.log"
      status=$?
      echo $status>"$foutdir.status.log"
      if [ $status -ne 0 ]; then
        echo "ERROR:${script_basename}:$fscript_basename failed.  See error log \"$foutdir.err.log\"." >&2
        printf "(Running the difference workflow again will give you a prompt to remove this and all other erroneous output; see the --cleanup flag for options.)\n" >&2
      fi #Checking exit status
    fi #Checking for prior-not-good output
  fi #Checking for prior-good output
}
#Make the logging function available to GNU Parallel
#H/t to Malcolm Cook: http://lists.gnu.org/archive/html/parallel/2012-01/msg00025.html
export -f logandrunscript

#Clarification on return vs exit: http://stackoverflow.com/a/18663184
logged_success() {
  statlog="$1"
  if [ ! -r "$statlog" ]; then
    return 5 #File not found/readable
  fi
  logged_status="$(head -n1 "$statlog")"
  if [ "x$logged_status" != "x0" ]; then
    return 0
  fi
  return 1
}

#AJN TODO 20140826
count_script_errors() {
  #Parameters:
  # 1) node|edge|graph
  # 2) Target script, for checking exit statuses
  error_tally=0
  analysis_type="$1"
  target_script="$2"

  _tally() {
    if [ -r "$statlog" ]; then
      logged_status="$(head -n1 "$statlog")"
      if [ "x$logged_status" != "x0" ]; then
        error_tally=$(($error_tally+1))
      fi
    fi
  }
  if [ "$analysis_type" == "node" ]; then
    while read node_id; do
      statlog="${dwf_all_results_root}/by_node/${node_id}/${target_script}.status.log"
      _tally
    done <"$dwf_node_sequence_file"
  elif [ "$analysis_type" == "edge" ]; then
    node_id0=
    while read node_id1; do
      if [ ! -z "$node_id0" ]; then
        statlog="${dwf_all_results_root}/by_edge/${node_id0}/${node_id1}/${target_script}.status.log"
        _tally
      fi
      node_id0="$node_id1"
    done <"$dwf_node_sequence_file"
  elif [ "$analysis_type" == "graph" ]; then
    statlog="${dwf_all_results_root}/by_graph/${dwf_sequence_id}/${target_script}.status.log"
    _tally
  else
    echo "ERROR:$0:count_script_errors called with bad first argument (should be 'node', 'edge', or 'graph'), received: ${analysis_type}." >&2
    exit 1
  fi
  echo $error_tally
}

my_inorder_parallel="parallel --keep-order -j$num_jobs"


#Create the sequence list.
logandrunscript graph "$script_dirname/make_sequence_list.sh" "$dwf_sequence_id"
any_errors=$(count_script_errors graph "make_sequence_list.sh")
if [ $any_errors -gt 0 ]; then
  echo "Note: Something went wrong making the sequence list.  Quitting.  See above error log for notes on what went wrong (grep for 'ERROR: ')." >&2
  exit 1
fi
#(This next variable is hard-coded between here and the make_sequence_list.sh script.)
export dwf_node_sequence_file="${dwf_all_results_root}/by_graph/make_sequence_list.sh/sequence_nodes.txt"

#Bail out if any errors were found in the loop.
if [ $any_errors -gt 0 ]; then
  echo "Note: Encountered $any_errors errors in the E01 loop.  Quitting.  See above error log for notes on what went wrong (grep for 'ERROR: ')." >&2
  exit 1
fi


#Link the disk images.
$my_inorder_parallel \
  echo "Note: Linking disk images for \"{}\"." \>\&2 \; \
  logandrunscript node "$script_dirname/link_disk.sh" {} \; \
  :::: "$dwf_node_sequence_file"
any_errors=$(count_script_errors node "link_disk.sh")

#Bail out if any errors were found in the loop.
if [ $any_errors -gt 0 ]; then
  echo "Note: Encountered $any_errors errors in the disk image linking loop.  Quitting.  See above error log for notes on what went wrong (grep for 'ERROR: ')." >&2
  exit 1
fi


#Create Fiwalk DFXML, including unallocated content.
$my_inorder_parallel \
  echo "Note: Starting Fiwalk all-files processing for \"{}\"." \>\&2 \; \
  logandrunscript node "$script_dirname/make_fiwalk_dfxml_all.sh" {} \; \
  :::: "$dwf_node_sequence_file"
any_errors=$(count_script_errors node "make_fiwalk_dfxml_all.sh")

#Bail out if any errors were found in the loop.
if [ $any_errors -gt 0 ]; then
  echo "Note: Encountered $any_errors errors in the Fiwalk loop.  Quitting.  See above error log for notes on what went wrong (grep for 'ERROR: ')." >&2
  exit 1
fi


#Create Fiwalk DFXML output directories after all E01 output's successfully done
$my_inorder_parallel \
  echo "Note: Starting Fiwalk allocated-only processing for \"{}\"." \>\&2 \; \
  logandrunscript node "$script_dirname/make_fiwalk_dfxml_alloc.sh" {} \; \
  :::: "$dwf_node_sequence_file"
any_errors=$(count_script_errors node "make_fiwalk_dfxml_alloc.sh")

#Bail out if any errors were found in the loop.
if [ $any_errors -gt 0 ]; then
  echo "Note: Encountered $any_errors errors in the Fiwalk loop.  Quitting.  See above error log for notes on what went wrong (grep for 'ERROR: ')." >&2
  exit 1
fi


#Try validating Fiwalk output with DFXML schema
$my_inorder_parallel \
  echo "Note: Validating Fiwalk allocated-only results from \"{}\"." \>\&2 \; \
  logandrunscript node "$script_dirname/validate_fiwalk_dfxml_alloc.sh" {} \; \
  :::: "$dwf_node_sequence_file"
any_errors=$(count_script_errors node "validate_fiwalk_dfxml_alloc.sh")

$my_inorder_parallel \
  echo "Note: Validating Fiwalk all-files results from \"{}\"." \>\&2 \; \
  logandrunscript node $script_dirname/validate_fiwalk_dfxml_all.sh" {} "\; \
  :::: "$dwf_node_sequence_file"
any_errors=$(count_script_errors node "validate_fiwalk_dfxml_all.sh")

#Tolerate errors with DFXML validation for now.


#Create differential DFXML output directories after all Fiwalk output is successfully done
$my_inorder_parallel \
  echo "Note: Starting differential DFXML processing, vs. baseline, for \"{}\"." \>\&2 \; \
  logandrunscript edge $script_dirname/make_differential_dfxml_baseline.sh" {} "\; \
  :::: "$dwf_node_sequence_file"
any_errors=$(count_script_errors edge "make_differential_dfxml_baseline.sh")

$my_inorder_parallel \
  echo "Note: Starting differential DFXML processing, vs. previous image, for \"{}\"." \>\&2 \; \
  logandrunscript edge "$script_dirname/make_differential_dfxml_prior.sh" {} \; \
  :::: "$dwf_node_sequence_file"
any_errors=$(count_script_errors node "make_differential_dfxml_prior.sh")

#Tolerate errors with from-baseline differential DFXML processing for now.
#However, the from-prior differential DFXML feeds into another script, so check it for errors.
#Bail out if any errors were found in the loop.
if [ $any_errors -gt 0 ]; then
  echo "Note: Encountered $any_errors errors making differential DFXML from the prior image.  Quitting.  See above error log for notes on what went wrong (grep for 'ERROR: ')." >&2
  exit 1
fi


#Create sector hashes of new files
$my_inorder_parallel \
  echo "Note: Starting new-file sector hashing \"{}\"." \>\&2 \; \
  logandrunscript edge "$script_dirname/make_new_file_sector_hashes.sh" {} \; \
  :::: "$dwf_node_sequence_file"
any_errors=$(count_script_errors edge "make_new_file_sector_hashes.sh")


#Tolerate errors with sector hashing for now.


#Create RDS-formatted output from Fiwalk DFXML
$my_inorder_parallel \
  echo "Note: Starting RDS re-formatting for \"{}\"." \>\&2 \; \
  logandrunscript edge "$script_dirname/make_rds_format.sh" {} \; \
  :::: "$dwf_node_sequence_file"
any_errors=$(count_script_errors edge "make_rds_format.sh")

#Bail out if any errors were found in the loop.
if [ $any_errors -gt 0 ]; then
  echo "Note: Encountered $any_errors errors in the RDS conversion loop.  Quitting.  See above error log for notes on what went wrong (grep for 'ERROR: ')." >&2
  exit 1
fi


#Create CybOX-formatted output from RDS output
$my_inorder_parallel \
  echo "Note: Starting CybOX re-formatting for \"{}\"." \>\&2 \; \
  logandrunscript edge "$script_dirname/make_cybox_format.sh" {} \; \
  :::: "$dwf_node_sequence_file"
any_errors=$(count_script_errors edge "make_cybox_format.sh")

#Bail out if any errors were found in the loop.
if [ $any_errors -gt 0 ]; then
  echo "Note: Encountered $any_errors errors in the CybOX conversion loop.  Quitting.  See above error log for notes on what went wrong (grep for 'ERROR: ')." >&2
  exit 1
fi


#Create RE output directories after all E01 output's successfully done.
#(Creating per-image RE immediately after creating the E01 (and similarly with Fiwalk) means basically trying to integrate Make again: Suddenly, there's a piecemeal, per-tarball dependency graph that has to be defined. A Bash array could probably do it, but recovering from failure becomes tedious right-quick.)
$my_inorder_parallel \
  echo "Note: Starting RegXML Extractor processing for \"{}\"." \>\&2 \; \
  logandrunscript node "$script_dirname/invoke_regxml_extractor.sh" {} \; \
  :::: "$dwf_node_sequence_file"
any_errors=$(count_script_errors node "invoke_regxml_extractor.sh")

#Bail out if any errors were found in the loop.
if [ $any_errors -gt 0 ]; then
  echo "Note: Encountered $any_errors errors in the sequence's individual-processing loop.  Quitting.  See above error log for notes on what went wrong (grep for 'ERROR: ')." >&2
  exit 1
fi


#Insert Perl module results; non-critical for now.
$my_inorder_parallel \
  echo "Note: Starting Perl modules on RegXML Extractor hives for \"{}\"." \>\&2 \; \
  logandrunscript node "$script_dirname/run_reg_perl.sh" {} \; \
  :::: "$dwf_node_sequence_file"
any_errors=$(count_script_errors node "run_reg_perl.sh")
if [ $any_errors -gt 0 ]; then
  echo "Note: Encountered $any_errors errors while generating Perl results.  Continuing; the Perl modules are experimental for purposes of the differencing workflow." >&2
fi


#Create the deltas dataset for the whole sequence
logandrunscript graph "$script_dirname/make_sequence_deltas.sh" "$dwf_sequence_id" 
any_errors=$(count_script_errors graph "make_sequence_deltas.sh")
if [ $any_errors -gt 0 ]; then
  echo "Error: Something went wrong aggregating the sequence results into SQLite.  Quitting.  See above error log for notes on what went wrong (grep for 'ERROR: ')." >&2
  exit 1
fi


#Export the results to Postgres
logandrunscript graph "$script_dirname/export_sqlite_to_postgres.sh" "$dwf_sequence_id" 
any_errors=$(count_script_errors graph "export_sqlite_to_postgres.sh")
if [ $any_errors -gt 0 ]; then
  echo "Error: Something went wrong exporting the SQLite to Postgres.  Quitting.  See above error log for notes on what went wrong (grep for 'ERROR: ')." >&2
  echo "Warning: At this point you probably need to delete some records from Postgres.  See the error log for export_sqlite_to_postgres.sh, there are some DELETE statements pre-built." >&2
  exit 1
fi


popd >/dev/null
