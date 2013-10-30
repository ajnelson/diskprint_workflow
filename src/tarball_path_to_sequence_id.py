#!/opt/local/bin/python3.3

"""
This script takes an absolute path to a Diskprint tarball and returns the ID of the sequence that ends with that tarball.

Note this script presently assumes that there is a 1:1 relationship between sequence ends and tarball paths.  This might not be true in the future.
"""

__version__ = "0.0.1"

import logging
import differ_library
import sys

def main():
    global args

    (conn, cursor) = differ_library.db_conn_from_config_path(args.config)

    cursor.execute("""\
SELECT
  osetid,
  appetid,
  sequenceid
FROM
  diskprint.sequence AS sequence,
  diskprint.storage AS storage
WHERE
  sequence.end_slicehash = storage.slicehash AND
  storage.location = %s
;
    """, (args.tarball_path,))
    rows = [row for row in cursor]
    if len(rows) == 0:
        raise Exception("Could not find any sequence ending with tarball path %r." % args.tarball_path)
    elif len(rows) > 1:
        raise Exception("Could not find a unique sequence ending with tarball path %r.  An initial, admittedly fragile, assumption of this script is now invalid." % args.tarball_path)

    #Format and output the sequence identifier
    sequence_identifier = "%(osetid)s-%(appetid)s-%(sequenceid)d" % rows[0]
    #(Don't include a newline)
    sys.stdout.write(sequence_identifier)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", help="Configuration file", default="differ.cfg")
    parser.add_argument("-d", "--debug", help="Enable debug printing", action="store_true")
    parser.add_argument("tarball_path")
    args = parser.parse_args()

    logging.basicConfig(level=logging.DEBUG if args.debug else logging.INFO)

    main()
