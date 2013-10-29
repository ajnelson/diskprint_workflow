#!/opt/local/bin/python2.7

"""
This script exits 0 status on concluding a tarball path is of a tarball sequence end.

It exits 1 if it concludes otherwise, or can't find the tarball.
"""

__version__ = "0.3.0"

import sys
import os
import argparse
import logging

import differ_library

def main():
    global args

    (inconn,incursor) = differ_library.db_conn_from_config_path(args.config)

    #Ensure that the tarball path is in the database.
    incursor.execute("""
SELECT
  COUNT(*) AS tally
FROM
  diskprint.storage
WHERE
  location = %s
;
    """, (args.slice_path,))
    inrows = [row for row in incursor]
    if len(inrows) != 1:
        raise Exception("Could not find tarball path in diskprint.storage table: %r." % args.slice_path)

    #Check that the tarball path is to a sequence end.
    incursor.execute("""\
SELECT
  *
FROM
  diskprint.storage AS storage
WHERE
  storage.location = %s AND
  storage.slicehash IN (
    SELECT DISTINCT
      end_slicehash
    FROM
      storage.sequence
  )
;
    """, (args.slice_path,))
    inrows = [row for row in incursor]
    if len(inrows) != 1:
        logging.error("Did not retrieve a single vetted tarball path; got %r instead.  Concluding this is not a sequence end." % len(inrows))
        sys.exit(1)
    #Otherwise, we're good.

if __name__ == "__main__":
    parser = argparse.ArgumentParser() 
    parser.add_argument("slice_path", help="Absolute path to disk slice tarball; must exist in slices table.")
    parser.add_argument("--config", help="Configuration file", default="differ.cfg")
    parser.add_argument("--debug", help="Enable debug printing", action="store_true")
    args = parser.parse_args()

    logging.basicConfig(
      format='%(asctime)s %(levelname)s: %(message)s',
      datefmt='%Y-%m-%dT%H:%M:%SZ',
      level=logging.DEBUG if args.debug else logging.INFO
    )

    main()
