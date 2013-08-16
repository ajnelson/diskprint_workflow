#!/bin/bash

#This script augments OS X shells so:
# * MacPort libraries and headers are included in linking.
# * The ~/.bashrc file is included in the shell environment (for newer shell sessions than this script's invoker)

if [ "x$(uname -s)" != "xDarwin" ]; then
  echo "Error: This script is for OS X only." >&2
  exit 1
fi

cat <<EOF >>~/.bashrc
export LIBRARY_PATH="/opt/local/lib:\$LIBRARY_PATH"
export LD_LIBRARY_PATH="/opt/local/lib:\$LD_LIBRARY_PATH"
export C_INCLUDE_PATH="/opt/local/include:\$C_INCLUDE_PATH"
export CPLUS_INCLUDE_PATH="/opt/local/include:\$CPLUS_INCLUDE_PATH"
EOF

#If you would like an explanation of these next lines, this madness is decently summarized at: <http://stackoverflow.com/a/415444/1207160>.
#The recursion checks are here in case a user has soft-linked their ~/.profile to ~/.bashrc.
if [ "x$(grealpath $HOME/.profile)" != "x$(grealpath $HOME/.bashrc)" ]; then
  cat <<EOF >>~/.profile
if [ "x$$DISKPRINT_BASHRC_UPDATES_IN_PLACE" != "xyes" ]; then
  export DISKPRINT_BASHRC_UPDATES_IN_PLACE=yes
  [[ -r ~/.bashrc ]] && . ~/.bashrc
fi
EOF
fi
