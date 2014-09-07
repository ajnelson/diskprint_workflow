#!/opt/local/bin/python3.3

"""
This program prints a single path to a requested node data component.  For instance, pass 'disk 123-4-567-8-90' to get the path to the disk image file of node_id 123-4-etc.
"""

__version__ = "0.1.0"

import logging
import os

_logger = logging.getLogger(os.path.basename(__file__))

import differ_library

def main():
    global args
    (conn, cursor) = differ_library.db_conn_from_config_path(args.config)

    (osetid, appetid, sliceid) = differ_library.split_node_id(args.node_id)

    cursor.execute("""
SELECT
  location
FROM
  diskprint.storage
WHERE
  filetype = %s AND
  osetid = %s AND
  appetid = %s AND
  sliceid = %s
""", (args.component, osetid, appetid, sliceid))
    rows = [row for row in cursor]

    if len(rows) > 1:
        _logger.debug("osetid = %r." % osetid)
        _logger.debug("appetid = %r." % appetid)
        _logger.debug("sliceid = %r." % sliceid)
        _logger.debug("component = %r." % args.component)
        raise ValueError("Retrieved %d rows from database; expecting at most 1.")

    for row in rows:
        print(row["location"])

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", help="Configuration file", default="differ.cfg")
    parser.add_argument("--debug", help="Turn on debug-level logging.", action="store_true")
    parser.add_argument("component", help="One of 'disk', 'ram', 'pcap'.")
    parser.add_argument("node_id", help="osetid-appetid-sliceid.")
    args = parser.parse_args()

    logging.basicConfig(level=logging.DEBUG if args.debug else logging.INFO)

    main()
