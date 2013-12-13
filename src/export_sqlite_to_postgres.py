#!/opt/local/bin/python2.7

__version__ = "0.1.3"

import os
import sys
import sqlite3
import argparse
import logging

import differ_library

def insert_db_postgres(cursor, table_name, update_dict):
    if len(update_dict.keys()) > 0:
        sql_insert_columns = []
        sql_insert_values = []
        for k in update_dict.keys():
            sql_insert_columns.append(k)
            sql_insert_values.append(update_dict[k])
        sql_insert_statement = "INSERT INTO diskprint." + table_name + "(" + ",".join(sql_insert_columns) + ") VALUES(" + ",".join(["%s"] * len(sql_insert_columns)) + ");"
        try:
            cursor.execute(sql_insert_statement, tuple(sql_insert_values))
        except:
            sys.stderr.write("Failed insertion.\nStatement:\t" + sql_insert_statement + "\nData:\t" + str(tuple(sql_insert_values)) + "\n")
            raise

def main():
    global args
    (outconn, outcursor) = differ_library.db_conn_from_config_path(args.config)

    inconn = sqlite3.connect(args.inputsqlite)
    inconn.row_factory = sqlite3.Row
    incursor = inconn.cursor()

    #Get translation dictionary for cell actions
    outcursor.execute("SELECT * FROM diskprint.cell;")
    action_text_to_id = dict()
    for outrow in outcursor:
        action_text_to_id[outrow["actiontype"]] = outrow["actionid"]
    logging.debug("Cell action translation dictionary:\n\t%r" % action_text_to_id)
    
    #Populate Hive table and get new ID's assigned by auto-incrementor
    #The insert-then-commit operation should guarantee Postgres is doling out unique IDs.
    in_to_out_hiveid = dict()
    for inrow in incursor.execute("SELECT * FROM hive;"):
        indict = dict()
        outdict = dict()
        for k in inrow.keys():
            indict[k] = inrow[k]
        for k in ["hivepath", "osetid", "appetid", "sequenceid"]:
            outdict[k] = inrow[k]
        #Inline function for maybe-once repetition
        def _fetch(od):
            outcursor.execute("""
              SELECT
                *
              FROM
                diskprint.hive
              WHERE
                hivepath = %s AND osetid = %s AND appetid = %s AND sequenceid = %s
              ;
            """, (od["hivepath"], od["appetid"], od["osetid"], od["sequenceid"]))
            return [row for row in outcursor]
        #checkrows should ultimately have just one record in it from the database, from which we get the translated ID of the hive sequence (hiveid identifies sequences)
        checkrows = _fetch(outdict)
        if len(checkrows) > 1:
            logging.error("The diskprint.hive table should have a unique ID for this dictionary, but returned multiple records: %r." % outdict)
            if len(in_to_out_hiveid) > 0:
                logging.info("You may want to issue this query to undo changes made by this script, after looking at the table:\n\tDELETE FROM diskprint.hive WHERE hiveid IN (%s);" % ",".join(map(str, in_to_out_hiveid.values())))
            sys.exit(1)
        elif len(checkrows) == 0:
            insert_db_postgres(outcursor, "hive", outdict)
            outconn.commit()
            checkrows = _fetch(outdict)
            if len(checkrows) != 1:
                logging.error("Could not retrieve unique record that was just inserted; something about the database state is incorrect.  Expected to get 1 record, got %d." % len(checkrows))
                logging.info("Fetching dictionary: %r." % outdict)
                logging.info("Records: %r." % checkrows)
                sys.exit(1)
        in_to_out_hiveid[indict["hiveid"]] = checkrows[0]["hiveid"]

    logging.debug("Hive ID translation dictionary:\n\t%r" % in_to_out_hiveid)
    hive_ids_str = ",".join(map(str, in_to_out_hiveid.values()))
    logging.info("If at any point after this the script fails, you should investigate and probably delete Postgres records with these rollback queries:\n\tDELETE FROM diskprint.hive WHERE hiveid IN (%s);\n\tDELETE FROM diskprint.regdelta WHERE hiveid IN (%s);" % (hive_ids_str, hive_ids_str))

    #Check for previous export of the mutation records
    outcursor.execute("""SELECT COUNT(*) AS tally FROM diskprint.regdelta WHERE hiveid IN (%s);""" % hive_ids_str)
    tallyoutrows = [row for row in outcursor]
    if len(tallyoutrows) != 1:
        logging.error("Not sure how, but a SELECT COUNT from Postgres didn't return 1 row; it returned %d.  Quitting." % len(tallyoutrows))
        exit(1)
    tally_postgres = tallyoutrows[0]["tally"]
    incursor.execute("""SELECT COUNT(*) AS tally FROM regdelta;""")
    tallyinrows = [row for row in incursor]
    if len(tallyinrows) != 1:
        logging.error("Not sure how, but a SELECT COUNT from SQLite didn't return 1 row; it returned %d.  Quitting." % len(tallyinrows))
        exit(1)
    tally_sqlite = tallyinrows[0]["tally"]
    if tally_postgres > 0:
        logging.error("Some records for the hives in this sequential analysis are already in Postgres.  Here is how the count compares to the SQLite that was about to be imported:\n\tPostgres\t%d\n\tSQLite\t%d" % (tally_postgres,tally_sqlite))
        logging.info("Given you invoked this script, you probably want the export to run to completion.  Clear away the records by issuing the DELETE queries above in the Postgres server, and then you can re-run this script and it should complete.") 
        exit(1)

    #Export the mutation records
    bailout = False
    for inrow in incursor.execute("SELECT * FROM regdelta;"):
        #Build output dictionary (we're about to tweak it)
        outdict = dict()
        for k in inrow.keys():
            outdict[k] = inrow[k]
        #Translate records
        outdict["hiveid"] = in_to_out_hiveid.get(inrow["hiveid"])
        outdict["appetid"] = inrow["appetid"]
        outdict["osetid"] = inrow["osetid"]
        outdict["sequenceid"] = inrow["sequenceid"]
        outdict["sliceid"] = inrow["sliceid"]
        if outdict["hiveid"] is None:
            logging.error("Failed to translate a hiveid: %r was not found." % inrow["hiveid"])
            logging.info("Hive ID translation dictionary:\n\t%r" % in_to_out_hiveid)
            bailout = True
        outdict["iskeybefore"] = inrow["iskeybefore"] == 1
        outdict["iskeyafter"] = inrow["iskeyafter"] == 1
        outdict["cellaction"] = action_text_to_id.get(inrow["cellaction"])
        if outdict["cellaction"] is None:
            logging.error("Failed to translate a cell action: %r not in table 'cell'." % inrow["cellaction"])
            bailout = True
        #Fail out if something didn't translate
        if bailout:
            logging.warning("You may want to purge the regdelta records from Postgres (this script was in the process of inserting them).  See the above DELETE queries.")
            exit(1)

        #Ship it!
        insert_db_postgres(outcursor, "regdelta", outdict)
    outconn.commit()

if __name__ == "__main__":
    parser = argparse.ArgumentParser() 
    parser.add_argument("inputsqlite", help="The SQLite database to export to Postgres")
    parser.add_argument("--config", help="Configuration file", default="differ.cfg")
    parser.add_argument("--debug", help="Enable debug printing", action="store_true")
    args = parser.parse_args()

    logging.basicConfig(
      format='%(asctime)s %(levelname)s: %(message)s',
      datefmt='%Y-%m-%dT%H:%M:%SZ',
      level=logging.DEBUG if args.debug else logging.INFO
    )

    main()
