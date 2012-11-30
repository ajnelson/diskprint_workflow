#!/usr/bin/python2.6
"""
Produces a sequence list ending at the given disk slice.
"""

__version__ = "0.1.1"

import os, sys
import argparse
import logging
from ConfigParser import ConfigParser
import psycopg2, psycopg2.extras

def main():
    global args

    if not os.path.isfile(args.slice_path):
        raise Exception("Invoked on non-existent path '%s'." % args.slice_path)

    loglvl = logging.DEBUG if args.debug else logging.INFO
    logging.basicConfig(
      format='%(asctime)s %(levelname)s: %(message)s',
      datefmt='%Y-%m-%dT%H:%M:%SZ',
      level=loglvl
    )

    config = ConfigParser()
    config.optionxform = str #Without this, config options are case insensitive and the parser pukes on ".exe=something" and ".EXE=somethingelse"
    config.read(args.config)
    configrootdict = dict()
    for (n,v) in config.items("root"):
        configrootdict[n]=v
    pwfilepath = configrootdict.get("DBpasswordfile")
    if os.path.isfile(pwfilepath):
        configrootdict["DBpassword"] = open(pwfilepath, "r").read().strip()

    conn_string = "host='%(DBserverIP)s' dbname='%(DBname)s' user='%(DBusername)s' password='%(DBpassword)s'" % configrootdict
    #logging.debug("conn_string: \"%s\"." % conn_string)
    conn = psycopg2.connect(conn_string)
    conn.autocommit = True
    cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    cursor.execute("""
        SELECT
          slice.sliceid, storage.location
        FROM
          storage, slice
        WHERE
          slice.slicehash = storage.slicehash AND
          location = %s;
    """, (args.slice_path,))
    returned_rows = [row for row in cursor]
    if len(returned_rows) != 1:
        raise Exception("Error: unexpected data: Expected only one sliceid to match '%s', got %d." % (args.slice_path, len(returned_rows)))
    slice_id = returned_rows[0]["sliceid"]

    #Build chain of slice_id's
    ids_reversed = [slice_id]
    earliest_id = slice_id
    while True:
        cursor.execute("""
            SELECT
              slicepredecessorid
            FROM
              slice
            WHERE
              sliceid = %s;
        """, (earliest_id,))
        returned_rows = [row for row in cursor]
        if len(returned_rows) == 0:
            raise Exception("Missing data: sliceid %d's parent not present in slice table." % earliest_id)
        elif len(returned_rows) > 1:
            raise Exception("Ambiguous history: A disk slice can't have two immediately preceding slices.")

        earliest_id = returned_rows[0]["slicepredecessorid"]
        if earliest_id is None:
            #Done with this sequence.
            break
        else:
            if earliest_id in ids_reversed:
                raise Exception("Encountered preceding-slice loop: sliceid %d already in sliceid list." % earliest_id)
            ids_reversed.append(earliest_id)
    ids_reversed.reverse()
    ids = ids_reversed

    #Look up paths of slice_id's
    #Fail out here if for some reason there are none:
    # "SQL doesn't allow an empty list in the IN operator, so your code should guard against empty tuples" <http://initd.org/psycopg/docs/usage.html#python-types-adaptation>.
    if len(ids) == 0:
        raise Exception("Somehow the ids list emptied; cannot proceed.")
    cursor.execute("""
        SELECT
          slice.sliceid, storage.location
        FROM
          storage, slice
        WHERE
          slice.slicehash = storage.slicehash AND
          sliceid in %s;
    """, (tuple(ids),) )

    #Build map of slice id to file system path
    id_to_path = dict()
    for row in cursor:
        id_to_path[int(row["sliceid"])] = row["location"]

    #Build list of file system paths
    paths = []
    for id in ids:
        try:
            paths.append(id_to_path[id])
        except:
            sys.stderr.write("Debug: Was looking up id=%d\n" % id)
            raise
        
    #Output paths
    for path in paths:
        print(path)

if __name__ == "__main__":
    script_path = os.path.abspath(sys.argv[0])

    parser = argparse.ArgumentParser()
    parser.add_argument("slice_path", help="Absolute path to disk slice tarball; must exist in slices table.")
    parser.add_argument("--config", help="Configuration file", default=script_path + ".cfg")
    parser.add_argument("--debug", help="Turn on debug-level logging.", action="store_true")
    args = parser.parse_args()

    main()
