#!/bin/bash

# Input:
#  * Absolute path to tarball.
#  * Absolute path to desired .E01 file (must not exist yet).
# Output:
#  * .E01 file and three stderr logs (hopefully empty).
# All intermediary output is deleted on successful libewf compression.

#Test prerequisites
usage() {
  echo "Usage: $0 <tarball path> <desired E01 path>" >&2
}

if [ "$(which ewfacquire)" == "" ]; then
  echo "Cannot find ewfacquire; install libewf with MacPorts." >&2
  echo "> sudo port install libewf" >&2
  exit 1
fi

if [ "$(which qemu-img)" == "" ]; then
  echo "Cannot find qemu-img; install qemu with MacPorts." >&2
  echo "> sudo port install qemu"
fi

if [ $# -lt 2 ]; then
  usage
  exit 1
fi

if [ ! -f "$1" ]; then
  usage
  echo "Tarball path must exist." >&2
  exit 1
fi

if [ -e "$2" ]; then
  usage
  echo "E01 path must not exist." >&2
  exit 1
fi

#Define variables
bash_pid=$$
script_name=$(basename "$0")
tarball_name=$(basename "$1")
diskprint_name=${tarball_name/%.tar.gz/}
e01_path="$2"
e01_dir="$(dirname "$e01_path")"
iso_path="${e01_path/%.E01/.iso}"
tarball_extract_dir="$e01_dir/vmware_dump"

#Some debug prints
echo "Debug: tarball_name: $tarball_name" >&2
echo "Debug: diskprint_name: $diskprint_name" >&2
echo "Debug: e01_dir: $e01_dir" >&2
echo "Debug: iso_path: $iso_path" >&2
echo "Debug: tarball_extract_dir: $tarball_extract_dir" >&2

#Work
mkdir -p "$e01_dir"
mkdir -p "$tarball_extract_dir"

pushd "$e01_dir" >/dev/null

#Extract VM from tarball
echo "Extracting .tar.gz ..." >&2
tar -xz -f "$1" -C"$tarball_extract_dir"
status=$?
if [ $status -ne 0 ]; then
  echo "Error extracting tarball, status $status." >&2
  exit $status
fi
echo "Done." >&2

#Convert vmdk file
#Ignore resource fork files (._*)
vmdk_path="$(find "$tarball_extract_dir" -name '*.vmdk' -print | egrep -v '\/\._[^\/]+\.vmdk' | head -n1)"
if [ "$vmdk_path" == "" ]; then
  echo "Error: .vmdk file not found in tarball!" >&2
  exit 1
fi
echo "Debug: .vmdk file: $vmdk_path" >&2
echo "Converting .vmdk file to $iso_path ..." >&2
qemu-img convert "$vmdk_path" "$iso_path"
status=$?
if [ $status -ne 0 ]; then
  echo " Error, status $status; see $iso_path.qemu_errors.log." >&2
  exit $status
fi
echo "Done." >&2

#Convert iso file
echo "Converting .iso file to .E01 ..." >&2
#Note: The `echo yes` is to deal with one last confirmation ewfacquire throws at you.
echo yes | ewfacquire \
  -b64 \
  -B200000000000 \
  -c"fast" \
  -C"$diskprint_name" \
  -D"Converted VMDK of diskprint $diskprint_name" \
  -d "sha1" \
  -e"NIST NSRL crew" \
  -E"Evidence $diskprint_name" \
  -f"encase6" \
  -g"64" \
  -l"$e01_path.ewf_errors.log" \
  -m"fixed" \
  -M"logical" \
  -N"No other notes for $diskprint_name" \
  -o0 \
  -P512 \
  -r2 \
  -S2000GiB \
  -t"${e01_path/%.E01/}" \
  -w \
  "$iso_path"
status=$?
if [ $status -ne 0 ]; then
  cat "$e01_path.ewf_errors.log" >&2
  rm "$e01_path.ewf_errors.log"
  echo "Error, status $status; see error log $e01_path.ewf_errors.log." >&2
  exit $status
fi
echo "Done." >&2

#Cleanup
echo -n "Removing intermediary files ..." >&2
rm -rf "$tarball_extract_dir"
rm "$iso_path"
echo " Done." >&2

popd >/dev/null
