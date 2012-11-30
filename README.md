# Forensic differencing workflow

## Running

The workflow runs by invoking the script and passing the path to the last diskprint tarball, and the root directory of where your results will be planted.  For instance, the following commands:

    cd src/
    ./do_difference_workflow.sh /Volumes/DiskPrintStore/8504-1/7895-1/8504-1-7895-1-40.tar.gz results

Will create these directories:
* `src/results/Volumes/DiskPrintStore/8504-1/7895-1/8504-1-7895-1-10.tar.gz/`...
* `src/results/Volumes/DiskPrintStore/8504-1/7895-1/8504-1-7895-1-20.tar.gz/`...
* `src/results/Volumes/DiskPrintStore/8504-1/7895-1/8504-1-7895-1-30.tar.gz/`...
* `src/results/Volumes/DiskPrintStore/8504-1/7895-1/8504-1-7895-1-40.tar.gz/`...

That example assumes the sequence begins at 10 and ends at 40; the actual sequence is defined in the database and read by make_sequence_list.sh.

The differ.cfg file contains configuration information necessary for the database.

The workflow script can be safely killed with just a ctrl-c.  If anything does not complete, the error log will tell you what you need to do to resume the work.  Alternatively, simply running the script again will tell you what you need to do to resume the work.  Usually you will need to just delete a partially-completed output directory.

You know it all worked when the last line of output is:
Done.

### Running as not-Alex

Alex ran this script with some home-locally installed code, instead of `sudo make install'ing everything.  The easiest way to run things is to just `su ajnelson' and run `source ~ajnelson/.bash_profile'.  The $PATH environment variable should be long after you do this.  (Ultimately, there should be a sudo make install or a dedicated differencing account.)

He had these necessary path updates in his .bashrc and .bash_profile:

    export PYTHONPATH="$HOME/local/src/regxml_extractor/lib:$PYTHONPATH"
    export PATH="$HOME/local/bin:/opt/local/bin:$PATH"
    export LIBRARY_PATH="/opt/local/lib:$LIBRARY_PATH"
    export LD_LIBRARY_PATH="/opt/local/lib:$LD_LIBRARYPATH"
    export C_INCLUDE_PATH="/opt/local/include:$C_INCLUDE_PATH"
    export CPLUS_INCLUDE_PATH="/opt/local/include:$CPLUS_INCLUDE_PATH"

If you do not want to compile and sudo-install the code, he doesn't have definite plans on returning, so you could just link against his home directory:

    export PYTHONPATH="/Users/ajnelson/local/src/regxml_extractor/lib:$PYTHONPATH"
    export PATH="/Users/ajnelson/local/bin:/opt/local/bin:$PATH"
    export LIBRARY_PATH="/opt/local/lib:$LIBRARY_PATH"
    export LD_LIBRARY_PATH="/opt/local/lib:$LD_LIBRARYPATH"
    export C_INCLUDE_PATH="/opt/local/include:$C_INCLUDE_PATH"
    export CPLUS_INCLUDE_PATH="/opt/local/include:$CPLUS_INCLUDE_PATH"

(This is currently the preferable solution for getting dfxml and fiwalk into the Python path.)

To export to the database, there is a configuration field DBpasswordfile, that should point to a file the executing user can read, and just has the database password.  Tweak src/differ.cfg, or supply your own config file with this field (note that other config files don't define the DBpasswordfile field).

## Data generated

If you want to blow away the data, do these three steps:
* Kill all the running instances of do_difference_workflow.sh
* Blow away the output root.
* Delete all contents from the vmslice database's hive and regdelta tables.
