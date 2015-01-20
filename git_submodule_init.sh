#!/bin/bash

git submodule init deps/python-cybox
git submodule sync deps/python-cybox
git submodule update deps/python-cybox

#The rest of this script is a pseudo-git-submodule tracker.  Will be replaced on transitioning to Git.

AFFLIB_REPO=https://github.com/simsong/AFFLIBv3.git
AFFLIB_COMMIT=82511e26b8920334c86a970ea19de3cdc84b4e5e
DFXMLSCHEMA_REPO=https://github.com/ajnelson/dfxml_schema.git
DFXMLSCHEMA_COMMIT=532f994ef652df030cd3f7b96b0870d3fffaec68
DFXML_REPO=https://github.com/simsong/dfxml.git
DFXML_COMMIT=4ec44381b27dbb541942a85091f8a7ae22a48eab
RE_REPO=https://github.com/ajnelson/regxml_extractor.git
RE_COMMIT=f724d85890bb3afa199550054a40dfbd505aa6b8

#Fetch Git repositories with git-submodule...only, in SVN.

if [ ! -d deps/regxml_extractor.git ]; then
  echo "Note: Cloning RegXML Extractor Git repository." >&2
  pushd deps/ >/dev/null
  git clone $RE_REPO regxml_extractor.git
  pushd regxml_extractor.git >/dev/null
  git checkout $RE_COMMIT
  popd >/dev/null
  popd >/dev/null
fi

if [ ! -d deps/dfxml_schema.git ]; then
  echo "Note: Cloning DFXML Schema Git repository." >&2
  pushd deps/ >/dev/null
  git clone $DFXMLSCHEMA_REPO dfxml_schema.git
  popd >/dev/null
fi

if [ ! -d deps/dfxml.git ]; then
  echo "Note: Cloning DFXML Git repository." >&2
  pushd deps/ >/dev/null
  git clone $DFXML_REPO dfxml.git
  popd >/dev/null
fi

if [ ! -d deps/AFFLIBv3.git ]; then
  echo "Note: Cloning AFFLib Git repository." >&2
  pushd deps/ >/dev/null
  git clone $AFFLIB_REPO AFFLIBv3.git
  popd >/dev/null
fi
