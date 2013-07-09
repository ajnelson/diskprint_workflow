
__version__ = "0.1.0"

import os
import sys
if sys.version_info < (3,0):
    from ConfigParser import ConfigParser
else:
    from configparser import ConfigParser
import psycopg2
import psycopg2.extras

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
    #logging.debug("conn_string: \"%s\"." % conn_string)                                                              
    conn = psycopg2.connect(conn_string)                                                                              
    conn.autocommit = True                                                                                            
    cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)                                                   
    return (conn, cursor)

#This 'main' logic is just for checking that the database is reachable with a given config file
if __name__ == "__main__":
    import argparse
    import logging

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
        logging.debug("Note: The slice table currently has %r entries." % inrows[0]["tally"])
