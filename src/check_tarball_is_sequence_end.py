#!/opt/local/bin/python2.7

"""
This script runs a somewhat complicated SQL query to determine if the requested tarball path is for a slice sequence end.  Here is a walkthrough of the query, as three set definitions.  The actual query includes some more straightforward table-joining components and the actual query parameter.

The set of all slices that have slice X as their immediate ancestor (which necessarily must match on osetid and appetid):

SELECT
  *
FROM
  diskprint.slice
WHERE
  osetid = Z AND
  appetid = Y AND
  slicepredecessorid = X
;


The set of all sliceids that precede some slice:

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
;


The set of all sliceids that precede no slice - that is, sequence ends:

SELECT
  *
FROM
  diskprint.slice
WHERE
  (osetid, appetid, sliceid) NOT IN (
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

__version__ = "0.2.1"

import sys
import os
import argparse
import logging

import differ_library

def main():
    global args

    (inconn,incursor) = differ_library.db_conn_from_config_path(args.config)

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

    incursor.execute("""
SELECT
  storage.*
FROM
  diskprint.slice AS slice,
  diskprint.storage AS storage
WHERE
  storage.location = %s AND
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
