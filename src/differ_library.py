
__version__ = "0.2.4"

import os
import sys
if sys.version_info < (3,0):
    from ConfigParser import ConfigParser
else:
    from configparser import ConfigParser
import psycopg2
import psycopg2.extras

import logging
_logger = logging.getLogger(os.path.basename(__file__))

def db_conn_from_config_path(cfg_path):
    """
    Return (Postgres connection, cursor) as a pair.
    """
    config = ConfigParser()
    config.optionxform = str #Without this, config options are case insensitive and the parser pukes on ".exe=something" and ".EXE=somethingelse"
    config.read(cfg_path)                                                                                          
    configrootdict = dict()                                                                                           
    for (n,v) in config.items("root"):                                                                                
        configrootdict[n]=v
    pwfilepath = configrootdict.get("DBpasswordfile")
    if not os.path.isfile(pwfilepath):
        raise Exception("Unable to find database password file: %r." % pwfilepath)
    configrootdict["DBpassword"] = open(pwfilepath, "r").read().strip()                                           
    
    conn_string = "host='%(DBserverIP)s' dbname='%(DBname)s' user='%(DBusername)s' password='%(DBpassword)s'" % configrootdict                                                                                                              
    #_logger.debug("conn_string: \"%s\"." % conn_string)
    conn = psycopg2.connect(conn_string)
    conn.autocommit = True                                                                                            
    cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    return (conn, cursor)

def split_sequence_id(sequence_id_string):
    parts = sequence_id_string.split("-")
    try:
        assert len(parts) == 5
    except AssertionError as e:
        _logger.error("Unexpected format of sequence_id_string: %r" % sequence_id_string)
        raise
    osetid = "-".join(parts[0:2])
    appetid = "-".join(parts[2:4])
    sequenceid = int(parts[4])
    return (osetid, appetid, sequenceid)

def tarball_sequence_from_sequence_triplet(cursor, sequence_triplet):
    start_slicehash = None
    end_slicehash = None
    sequence_id_parts = split_sequence_id(sequence_triplet)
    sql_get_bounding_hashes = """\
SELECT
  start_slicehash, end_slicehash
FROM
  diskprint.sequence AS sequence
WHERE
  sequence.osetid = %s AND
  sequence.appetid = %s AND
  sequence.sequenceid = %s
;"""
    cursor.execute(sql_get_bounding_hashes, sequence_id_parts)
    rows = [row for row in cursor]
    if len(rows) != 1:
        raise Exception("Unexpected results (%d rows, should be 1) from this query and these parameters: \n%s;\nParameters: %r." % (len(rows), sql_get_bounding_hashes, sequence_id_parts))
    start_slicehash = rows[0]["start_slicehash"]
    end_slicehash = rows[0]["end_slicehash"]

    #TODO I forget if there's a more efficient way to run a segment query with joins...pretty sure there is, given RDF query patterns.
    paths = []
    current_end_hash = end_slicehash
    sql_get_name_and_prev = """\
SELECT DISTINCT
  slicelineage.slicehash,
  slicelineage.predecessor_slicehash,
  storage.location
FROM
  diskprint.slicelineage AS slicelineage,
  diskprint.storage AS storage
WHERE
  storage.slicehash = slicelineage.slicehash AND
  slicelineage.slicehash = %s
;"""
    while True:
        cursor.execute(sql_get_name_and_prev, (current_end_hash,))
        rows = [row for row in cursor]
        if len(rows) != 1:
            _logger.debug("Row data:")
            for (row_no, row) in enumerate(rows):
                _logger.debug("%d\t%r" % (row_no, row))
            raise Exception("Unexpected results (%d rows, should be 1) from this query and these parameters: \n%s;\nParameters:%r." % (len(rows), sql_get_name_and_prev, (end_slicehash,)))
        paths.append(rows[0]["location"])
        if rows[0]["slicehash"] == start_slicehash:
            #Done.
            break
        current_end_hash = rows[0]["predecessor_slicehash"]
    paths.reverse()
    return paths

#This 'main' logic is just for checking that the database is reachable with a given config file
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--config", help="Configuration file", default="differ.cfg")
    parser.add_argument("--check", help="Check for database connectivity and exit", action="store_true")
    parser.add_argument("--debug", help="Enable debug printing", action="store_true")
    args = parser.parse_args()

    logging.basicConfig(
      format='%(asctime)s %(levelname)s: %(message)s',
      datefmt='%Y-%m-%dT%H:%M:%SZ',
      level=logging.DEBUG if args.debug else logging.INFO
    )

    if args.check:
        (conn,cursor) = db_conn_from_config_path(args.config)

        cursor.execute("SELECT COUNT(*) AS tally FROM diskprint.slice;")
        inrows = [row for row in cursor]
        _logger.debug("The slice table currently has %r entries." % inrows[0]["tally"])

        cursor.execute("SELECT COUNT(*) AS tally FROM diskprint.regdelta;")
        inrows = [row for row in cursor]
        _logger.debug("The regdelta table currently has %r entries." % inrows[0]["tally"])

        cursor.execute("SELECT * FROM diskprint.storage;")
        inrows = [row for row in cursor]
        import collections
        nonexists = []
        for row in inrows:
            if not os.path.exists(row["location"]):
                nonexists.append(row["location"])
        _logger.debug("There are %d tarballs in the database that aren't found in the file system." % len(nonexists))
        if len(nonexists) > 0:
            _logger.debug("They are:")
            for path in nonexists:
                _logger.debug("\t%s" % path)
