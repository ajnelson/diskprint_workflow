#!/bin/bash

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

#Note that this included script sets -e and -x, so errors will be caught appropriately.
source "${script_dir}/regxml_extractor.git/deps/install_dependent_packages-osx-10.7.sh"

sudo port install \
  coreutils \
  libewf \
  parallel \
  py27-dateutil \
  py27-psycopg2 \
  py33-dateutil \
  py33-psycopg2 \
  python27 \
  python33 \
  qemu

echo "Done."
