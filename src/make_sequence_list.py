#!/opt/local/bin/python2.7
"""
Produces a sequence list for the given sequence-identifying triplet.
"""

__version__ = "0.2.0"

import os, sys
import logging

import differ_library

def main():
    global args

    (conn, cursor) = differ_library.db_conn_from_config_path(args.config)

    #Output paths
    for path in differ_library.tarball_sequence_from_sequence_triplet(cursor, args.sequence_id):
        print(path)

if __name__ == "__main__":
    import argparse

    script_path = os.path.abspath(sys.argv[0])

    parser = argparse.ArgumentParser()
    parser.add_argument("sequence_id", help="Sequence identifier triplet.")
    parser.add_argument("--config", help="Configuration file", default=script_path + ".cfg")
    parser.add_argument("--debug", help="Turn on debug-level logging.", action="store_true")
    args = parser.parse_args()

    loglvl = logging.DEBUG if args.debug else logging.INFO
    logging.basicConfig(
      format='%(asctime)s %(levelname)s: %(message)s',
      datefmt='%Y-%m-%dT%H:%M:%SZ',
      level=loglvl
    )

    main()
