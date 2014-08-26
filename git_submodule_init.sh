#!/bin/bash

git submodule init deps/python-cybox
git submodule sync deps/python-cybox
git submodule update deps/python-cybox

#The rest of this script is a pseudo-git-submodule tracker.  Will be replaced on transitioning to Git.

AFFLIB_REPO=https://github.com/simsong/AFFLIBv3.git
AFFLIB_COMMIT=b0a36e392c26e4d9e95a85a41071d794d4b9ee73
DFXMLSCHEMA_REPO=https://github.com/ajnelson/dfxml_schema.git
DFXMLSCHEMA_COMMIT=b1329fe1e18e58afd762f96ae827f9593c470120
DFXML_REPO=https://github.com/simsong/dfxml.git
DFXML_COMMIT=eb79c78966d14024d0b6b617f16b703c93b5f72a
RE_REPO=https://github.com/ajnelson/regxml_extractor.git
RE_COMMIT=c466fc7fc0fe1865bbdac4c2cffdf977e5f348d3

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
