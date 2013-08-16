# Diskprint differencing workflow

This repository contains program configurations and calls used to process diskprints.  An overview of the diskprint project is available from [NIST](http://www.nsrl.nist.gov/Diskprints.htm).

NB: The workflow in this repository is meant to be run by a dedicated shell user account in a Mac OS X environment.  The account's Bash environment must be configured to allow for local compilation and installation by augmentations to various `$PATH` variables.  If not already configured, a script is included to complete configuration.


## Data

This workflow operates on tarballs of virtual machines generated with VMWare Fusion.  (VMWare Workstation appears to generate data in a sufficiently similar format, but has not been tested.)  A diskprint is effectively a sequence of tarballs of a single virtual machine.  At times of interest in the machine usage, the machine is paused and archived with `tar`.  Virtual machine snapshots are not currently used.  The tarballs are then annotated and stored.  Storage references and the metadata are loaded into a Postgres database; example SQL statements that illustrate the annotations are in the `examples/` directory of the [Diskprint database](https://github.com/ajnelson/diskprint_database).


## Initial setup

Before your first run, you will need to run these commands to guarantee your environment will support the differencing workflow:

    ./git_submodule_init.sh
    sudo deps/install_dependent_packages_(your supported OS here)
    deps/augment_shell.sh ; source ~/.bashrc
    ./bootstrap.sh

Note only one command needs to be run with `sudo`.  Everything else that requires compilation and installation is installed into your home directory (under `~/local`).

If `bootstrap.sh` fails, it should provide you sufficient instructions to fix things up so you can run it to completion.  If bootstrap worked, running it again will cause no changes.

To check to see if the execution environment's setup alright (without checking for the database being live), run this script:

    tests/check_env.sh


### Setting up the database

The database tables are managed in a separate repository, [`diskprint_database`](https://github.com/ajnelson/diskprint_database).

The `src/differ.cfg.sample` file in the workflow repository (not the database repository) contains configuration information necessary to connect to the database.  Copy it to `src/differ.cfg` and modify it to fit your environment.

Check that the database is queryable with this script:

    tests/check_db.sh


## Running

The workflow runs by invoking the script and passing the path to the last diskprint tarball of your sequence, and the root directory of where your results will be planted.  For instance, the following commands:

    cd src/
    ./do_difference_workflow.sh /Volumes/DiskPrintStore/8504-1/7895-1/8504-1-7895-1-40.tar.gz results

Will create these directories:
* `src/results/Volumes/DiskPrintStore/8504-1/7895-1/8504-1-7895-1-10.tar.gz/`...
* `src/results/Volumes/DiskPrintStore/8504-1/7895-1/8504-1-7895-1-20.tar.gz/`...
* `src/results/Volumes/DiskPrintStore/8504-1/7895-1/8504-1-7895-1-30.tar.gz/`...
* `src/results/Volumes/DiskPrintStore/8504-1/7895-1/8504-1-7895-1-40.tar.gz/`...

That example assumes the sequence begins at 10; the actual sequence is defined in the database and read by `make_sequence_list.sh`.

An easier approach to running the workflow is telling it to run on all available data; to do this, pass the flag "`--parallel-all`" instead of a tarball path.

This workflow is idempotent on success:  If everything worked, running it again will cause nothing to happen.


### Halting

The workflow script can be safely killed with just a ctrl-c.  If anything does not complete, the error log will tell you what you need to do to resume the work.  Alternatively, simply running the script again will tell you what you need to do to resume the work, and even will offer to do erroneous result cleanup (see the `--cleanup` option).

You will know it all worked when the last line of output is:

    Done.


## Data generated

If you want to erase all the derived data, do these three steps:
* Kill all the running instances of `do_difference_workflow.sh`
* Delete the output root (`results` in the above example).
* Delete all contents from the database's `regdelta` and `hive` tables.


### Updating data

In the event some data are found to have been erroneously ingested into the database, the data should be re-ingested.  Fortunately, this does not mean regenerating all of the data.

First, the cleanest approach to ensuring difference data are up-to-date is refreshing the two data tables.  In the Postgres service, `diskprints` database:

    DELETE FROM diskprint.regdelta;
    DELETE FROM diskprint.hive;

Running the workflow again with the `--re-export` flag will run only the export step.


## Debugging

Each script of the workflow records its stdout, stderr, and exit status (...`.sh.{out,err,status}.log`).  It would be helpful to have these logs with debugging support requests.


## Developing

Contributions are welcome!  To help understand this repository's development, these are the main Git branches:

* The `master` branch is operational code used to generate results.
* The `unstable` branch is development code, and is not guaranteed to work.
* The `staging` branch is code being tested for merging into the `master` branch.  `staging`  might not have a stable Git history (be reset to other versions of commits), in the interest of keeping `master`'s history fairly linear and comprehensible.

Contributions can safely target the `master` branch; `unstable` may live up to its name and thus be a bad partner-development target.  Pull requests will undergo review and testing before merging.
