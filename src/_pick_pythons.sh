#!/bin/bash

# This script is a library, just defining some variables.  Similar to what an Autotools configure script would define.

PYTHON2=`which python2.7`
for p in python3.4 python3.3 python3.2 python3; do
  set +e
  PYTHON3=`which $p`
  set -e
  if [ ! -z "$PYTHON3" ]; then
    break
  fi
done
if [ -z "$PYTHON3" ]; then
  set +x
  echo "Could not find Python 3.  Install from your package manager or the Python web site." >&2
  exit 1
fi

