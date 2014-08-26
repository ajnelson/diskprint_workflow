#!/bin/bash

#One-liner c/o http://stackoverflow.com/a/246128/1207160
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

#Note that this included script sets -e and -x, so errors will be caught appropriately.
source "${script_dir}/regxml_extractor.git/deps/install_dependent_packages-ubuntu-14.04.sh"

sudo apt-get install \
  coreutils \
  libewf-dev \
  libewf2 \
  ewf-tools \
  parallel \
  python-psycopg2 \
  python-setuptools \
  python3-psycopg2 \
  python3-setuptools \
  python2.7 \
  python3 \
  qemu

echo "Done."
