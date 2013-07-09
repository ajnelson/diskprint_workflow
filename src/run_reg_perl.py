#!/opt/local/bin/python3.3

"""
This program takes RegXML Extractor's output and runs Perl modules on the extracted hive files.
"""

__version__ = "0.1.0"

import os
import sys
import argparse
import logging
import subprocess

def main():
    global args
    if not os.path.isdir(args.re_out_dir):
        logging.error("Error: Expecting RegXML Extractor output directory as input.\n")
        sys.exit(1)

    os.makedirs(args.output_dir, exist_ok=True)

    #Build a list of all the hive files
    #TODO This should probably use linted.txt.
    hives = set()
    for (dirpath, dirnames, filenames) in os.walk(args.re_out_dir):
        for fn in filenames:
            if fn[-5:] == ".hive":
                hives.add(os.path.join(dirpath,fn))

    #For each hive file:
    #  Run perl modules via command line
    for hive in hives:
        #Build output file path as: Base output directory, "hive_file_<id>_<basename>_reg{dump,stats}..."
        hive_fiwalk_id = os.path.splitext(os.path.basename(hive))[0]
        #TODO Determine in-file-system basename
        output_prefix = "hive_file_%s_" % hive_fiwalk_id
        with open(os.path.join(args.output_dir, output_prefix + "regdump.txt"), "w") as regdump_out:
            with open(os.path.join(args.output_dir, output_prefix + "regdump.err.log"), "w") as regdump_err:
                logging.info("About to run regdump.pl on %r." % hive_fiwalk_id)
                rc_regdump = subprocess.call([
                  "perl",
                  "/opt/local/libexec/perl5.12/sitebin/regdump.pl",
                  hive,
                  "-r",
                  "-v"
                ], stdout=regdump_out, stderr=regdump_err)
                with open(os.path.join(args.output_dir, output_prefix + "regdump.status.log"), "w") as status_log_file:
                    status_log_file.write(str(rc_regdump))
                    status_log_file.close()

        with open(os.path.join(args.output_dir, output_prefix + "regstats.txt"), "w") as regstats_out:
            with open(os.path.join(args.output_dir, output_prefix + "regstats.err.log"), "w") as regstats_err:
                logging.info("About to run regstats.pl on %r." % hive_fiwalk_id)
                rc_regstats = subprocess.call([
                  "perl",
                  "/opt/local/libexec/perl5.12/sitebin/regstats.pl",
                  hive,
                  "-t"
                ], stdout=regstats_out, stderr=regstats_err)
                with open(os.path.join(args.output_dir, output_prefix + "regstats.status.log"), "w") as status_log_file:
                    status_log_file.write(str(rc_regstats))
                    status_log_file.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("re_out_dir", help="RegXML Extractor output directory")
    parser.add_argument("output_dir", help="Output directory of this script; doesn't need to exist")
    parser.add_argument("-d", "--debug", help="Enable debug printing", action="store_true")
    args = parser.parse_args()

    logging.basicConfig(
      format='%(asctime)s %(levelname)s: %(message)s',
      datefmt='%Y-%m-%dT%H:%M:%SZ',
      level=logging.DEBUG if args.debug else logging.INFO
    )

    main()
