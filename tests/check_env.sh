#!/bin/bash

# Run this script to see if the current executing environment will support the differencing workflow.

set -e
set -x

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
top_srcdir="${script_dir}/.."

source "${top_srcdir}/_env_extra.sh"
source "${script_dir}/_check.sh"

#Ensure we have Python 2 and 3 handy
test -x $PYTHON2
test -x $PYTHON3

#Check for global Python modules
$PYTHON2 -c 'import argparse'
$PYTHON2 -c 'import ConfigParser'
$PYTHON3 -c 'import configparser'
$PYTHON2 -c 'import psycopg2, psycopg2.extras'
$PYTHON3 -c 'import psycopg2, psycopg2.extras'

#Check for local Python modules
pushd "${top_srcdir}/src" >/dev/null
$PYTHON3 -c 'import dfxml'
$PYTHON2 -c 'import differ_library'
$PYTHON3 -c 'import differ_library'
popd >/dev/null

#Ensure libewf is installed
set +e
EWFACQUIRE=`which ewfacquire`
set -e
if [ -z "$EWFACQUIRE" ]; then
  set +x
  echo "Could not find ewfacquire; assuming libewf missing.  This workflow relies on libewf, so please install from a package manager or compile and install the latest version." >&2
  exit 1
fi

#Ensure libewf is linkable
EWFPREFIX=${EWFACQUIRE%/bin/ewfacquire}
for x in "$LIBRARY_PATH" "$LD_LIBRARY_PATH" "$C_INCLUDE_PATH" "$CPLUS_INCLUDE_PATH"; do
  if [ $(echo $x | grep "$EWFPREFIX" | wc -l) -eq 0 ]; then
    set +x
    echo "At least one of your environment variables is missing the libewf prefix ($EWFPREFIX); this is a problem for linking Fiwalk with libewf.  Check the library and include path variables in your .bashrc.  When they are, re-build Fiwalk." >&2
    exit 1
  fi
done

#Ensure Fiwalk linked libewf
FIWALK=`which fiwalk`
test -x $FIWALK
if [ $($FIWALK | grep 'NO LIBEWF SUPPORT' | wc -l) -eq 1 ]; then
  echo "Fiwalk" should have EWF support for this environment. >&2
  exit 1
fi

#Ensure RE is in the path
RESH=`which regxml_extractor.sh`
if [ ! -x $RESH ]; then
  echo "Could not find regxml_extractor.sh in your PATH; if you've run bootstrap.sh, check that your current shell reflects your ~/.bashrc state." >&2
  exit 1
fi

set +x
echo "All's well."
echo "Done."
