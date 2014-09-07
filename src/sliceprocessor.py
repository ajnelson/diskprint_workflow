#!/opt/local/bin/python2.7

"""
This script:
 * Reads the config file, optionally passed with a command-line flag.
 * Connects to the Postgres database.
 * Passes each sequence ID (label) to stdout.
"""

__version__ = "0.4.0"

import os
import sys
import argparse
import logging
import subprocess

_logger = logging.getLogger(os.path.basename(__file__))

import differ_library

def main():
    global args
    _logger.debug("Running main() of file: %r." % __file__)

    (inconn,incursor) = differ_library.db_conn_from_config_path(args.config)

    #Fetch work queue
    query = """
SELECT DISTINCT
  sequencelabel
FROM
  diskprint.namedsequence
;"""
    incursor.execute(query)
    _logger.info("Diskprint table Query: %s" % query)
    inrows = [row for row in incursor]

    for inrow in inrows:
        print(inrow["sequencelabel"])

    if len(inrows) == 0:
        _logger.info("No diskprints to process.")

    #Cleanup
    inconn.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", help="Configuration file", default="differ.cfg")
    parser.add_argument("-d", "--debug", help="Enable debug printing", action="store_true")
    args = parser.parse_args()

    logging.basicConfig(
      format='%(asctime)s %(levelname)s: %(message)s',
      datefmt='%Y-%m-%dT%H:%M:%SZ',
      level=logging.DEBUG if args.debug else logging.INFO
    )

    main()
