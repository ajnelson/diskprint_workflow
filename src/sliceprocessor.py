#!/opt/local/bin/python2.7

"""
(Direct Perl-to-Python translation of sliceprocessor.pl.)

This script:
 * Reads the config file, optionally passed with a command-line flag.
 * Connects to the Postgres database.
 * Selects all of the work queued up in diskprint.processqueue.
 * For each tarball, runs the differencing workflow and the fork slice script.
 * On successfully running both the differ and fork-slice, pops the tarball from the queue.
"""

__version__ = "0.2.1"

import os
import sys
import argparse
import logging
import subprocess

import differ_library

def main():
    global args
    logging.debug("Running main() of file: %r." % __file__)

    (inconn,incursor) = differ_library.db_conn_from_config_path(args.config)

    #Fetch work queue
    if args.tails_only:
        #This query is as in check_tarball_is_sequence_end.py, r574.
        query = """
SELECT
  storage.*
FROM
  diskprint.slice AS slice,
  diskprint.storage AS storage
WHERE
  storage.slicehash = slice.slicehash AND
  (slice.osetid, slice.appetid, slice.sliceid) NOT IN (
    SELECT
      s1.osetid,
      s1.appetid,
      s1.slicepredecessorid
    FROM
      diskprint.slice AS s1,
      diskprint.slice AS s2
    WHERE
      s1.osetid = s2.osetid AND
      s1.appetid = s2.appetid AND
      s1.slicepredecessorid = s2.sliceid
  )
;
        """
    else:
        query = """
SELECT
  pq.*
FROM
  diskprint.processqueue AS pq,
  diskprint.slice AS s
WHERE
  s.slicehash = pq.slicehash
ORDER BY
  sliceid DESC
;
        """
    incursor.execute(query)
    logging.info("Diskprint table Query: %s" % query)
    inrows = [row for row in incursor]
    any_found = 0
    for inrow in inrows:
        any_found += 1
        inrow_location = inrow["location"]
        logging.debug("PROCESS QUEUE LOCATION %s" % inrow_location)
        print(inrow_location)

    if any_found == 0:
        logging.info("No diskprints to process.")

    #Cleanup
    inconn.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--tails_only", help="Only work on last tarballs of sequences", action="store_true")
    parser.add_argument("--config", help="Configuration file", default="fork.cfg")
    parser.add_argument("-d", "--debug", help="Enable debug printing", action="store_true")
    args = parser.parse_args()

    logging.basicConfig(
      format='%(asctime)s %(levelname)s: %(message)s',
      datefmt='%Y-%m-%dT%H:%M:%SZ',
      level=logging.DEBUG if args.debug else logging.INFO
    )

    main()
