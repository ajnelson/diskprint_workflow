#!/bin/bash

# When this script runs successfully, it sets up the following:
#
#  * The current user will be able to compile and link tools without administrator rights - tools will be installed under the prefix ~/local.
#  * The system will have several required pacakges installed, including compiler tools (autotools), Ocaml, and Python 3.
#  * The current user will be able to run EWF programs, AFF programs, TSK programs, fiwalk, and hivexml
#  * Specific versions of software tracked by Git will be built and installed.  If this script is updated, the Git-tracked software will also be updated and re-built as necessary.
#
# The script aborts on any command not succeeding.
# The script aborts with a remedy message on finding something unsatisfactory with the execution environment.
# The script is progressively idempotent: Steps that succeeded in the past won't be repeated on further invocations.  (Consider this in the spirit of Make.)
#
# - AJN, 2013-05-24

set -e
set -x

source git_submodule_init.sh

#These flags are potentially raised at various steps.
AFFLIB_should_build=0
RE_should_build=0

#This global variable is modified from a function's local scope.
_should_build=0

#Vet environment's paths
if [ \
  $(echo "$PATH" | grep "$HOME/local" | wc -l) -lt 1 -o \
  \( "x$(uname -s)" == "xDarwin" -a $(echo "$C_INCLUDE_PATH" | grep "/opt/local" | wc -l) -lt 1 \) \
]; then
  set +x
  echo "" >&2
  echo "Error: One of your PATH variables is missing an augmentation we assume you'll have, so this local build will fail to link with needed libraries.  To finish running this script, run these commands and then re-run the script:" >&2
  echo "" >&2
  echo "   deps/augment_shell.sh" >&2
  echo "   source ~/.bashrc" >&2
  echo "" >&2
  exit 1
fi

#With RegXML Extractor downloaded, make sure everything will be buildable by installing the packages.
if [ "x$(which ocaml)" == "x" ]; then
  set +x
  echo "Error: ocaml wasn't detected, so it's likely you won't be able to build hivex.  Modify and run this command as an administrator to configure your package environment for building The Sleuth Kit and Hivex:" >&2
  echo "" >&2
  echo "    sudo deps/regxml_extractor.git/deps/install_dependent_packages-(your OS version here).sh" >&2
  echo "" >&2
  echo "(Mountain Lion's dependencies script is in the same directory, at install...10.8.sh.)" >&2
  echo "(If MacPorts fails on you with a complaint about xz or some random-looking port, its printed instructions are worth following.)" >&2
  echo "" >&2
  echo "These scripts should indicate what environments are supported by the difference workflow:" >&2
  echo "" >&2
  ls deps/install_dependent_packages*sh >&2
  echo "" >&2
  exit 1
fi

#Ensure Git repositories are checked out to version logged _in this script_.
_ensure_git_repo_commit() {
  REPO_REL_PATH=$1
  TARGET_COMMIT=$2

  _should_build=0

  pushd "$REPO_REL_PATH" >/dev/null
  CURRENT_COMMIT=$(git rev-parse HEAD)
  if [ -z "$CURRENT_COMMIT" ]; then
    set +x
    echo "Error: Could not get Git revision for repository at '$PWD'; unsure how to proceed." >&2
    exit 1
  fi
  if [ "$CURRENT_COMMIT" != "$TARGET_COMMIT" ]; then
    _should_build=1
    git fetch --all
    git checkout $TARGET_COMMIT
  fi
  popd >/dev/null
}
_ensure_git_repo_commit deps/dfxml.git $DFXML_COMMIT
_ensure_git_repo_commit deps/regxml_extractor.git $RE_COMMIT
RE_should_build=$_should_build
_ensure_git_repo_commit deps/AFFLIBv3.git $AFFLIB_COMMIT
AFFLIB_should_build=$_should_build
  
#Initialize RE Git submodules if not checked out already
if [ $RE_should_build -eq 1 -o ! -r deps/regxml_extractor.git/deps/sleuthkit/README.txt ]; then
  pushd deps/regxml_extractor.git >/dev/null
  git submodule init
  git submodule sync
  git submodule update
  RE_should_build=1
  popd >/dev/null
fi

#Build libaff
if [ "x$(which affconvert)" == "x" ]; then
  AFFLIB_should_build=1
fi
if [ $AFFLIB_should_build -eq 1 ]; then
  pushd deps/AFFLIBv3.git >/dev/null
  ./bootstrap.sh
  ./configure --prefix=$HOME/local
  make -j || make #If parallel make fails, re-run make to see what the error was
  make install
  popd >/dev/null
fi

#Ensure Fiwalk (and thus RegXML Extractor) are built:
# (1) With AFF and EWF support
# (2) Up-to-date
if [ "x$(which fiwalk)" == "x" -o \
  $(fiwalk | grep 'NO AFFLIB SUPPORT' | wc -l) -gt 0 -o \
  $(fiwalk | grep 'NO LIBEWF SUPPORT' | wc -l) -gt 0 \
]; then
  RE_should_build=1
fi

if [ $RE_should_build -eq 1 ]; then
  pushd deps/regxml_extractor.git >/dev/null
  git submodule sync
  deps/build_submodules.sh local
  echo "Note: Checking that afflib is linked into Fiwalk..." >&2
  test $(fiwalk | grep 'NO AFFLIB SUPPORT' | wc -l) -eq 0
  echo "Afflib link is good." >&2
  echo "Note: Checking that libewf is linked into Fiwalk..." >&2
  test $(fiwalk | grep 'NO LIBEWF SUPPORT' | wc -l) -eq 0
  echo "Libewf link is good." >&2
  ./bootstrap.sh
  ./configure --prefix=$HOME/local
  make 
  make install
  popd >/dev/null
fi

set +x
echo "Done." >&2
