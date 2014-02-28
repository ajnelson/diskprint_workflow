
#Include this file to update the PATH environment variables for installation local to *this repository checkout* (for multiple checkouts of the repository on the same system)

DWF_TOP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
export DWF_BUILD_PREFIX="${DWF_TOP_DIR}/local"

export PATH="$DWF_BUILD_PREFIX/bin:$PATH"
export LIBRARY_PATH="$DWF_BUILD_PREFIX/lib:/usr/local/lib:$LIBRARY_PATH"
export LD_LIBRARY_PATH="$DWF_BUILD_PREFIX/lib:/usr/local/lib:$LD_LIBRARY_PATH"
export C_INCLUDE_PATH="$DWF_BUILD_PREFIX/include:$C_INCLUDE_PATH"
export CPLUS_INCLUDE_PATH="$DWF_BUILD_PREFIX/include:$CPLUS_INCLUDE_PATH"
export PYTHONPATH="$DWF_BUILD_PREFIX/share/python2/lib:$PYTHONPATH"
