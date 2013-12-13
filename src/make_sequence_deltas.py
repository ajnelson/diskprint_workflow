#!/opt/local/bin/python3.3

"""
make_sequence_deltas.py: Aggregate differences in ouput of Fiwalk and RegXML Extractor.

For usage instructions, see the argument parser description below, or run this script without arguments.
"""

__version__ = "0.3.0"

import sys
import os
import argparse
import sqlite3
import collections
import logging
import dfxml

import differ_library

"""
AJN: Sorry, I realized pretty late that the slice type was a required field. This hard-coded variable can be deleted after the slice type is queried.
"""
#TODO Replace uses of this variable with database-supplied values.
PLACEHOLDER_SLICE_TYPE = "Function"

def time_string_from_cell(cell):
    if cell:
        mt = cell.mtime()
        if mt:
            return mt.iso8601()
    return None
        

def sliceid_from_regxml_path(path):
    """
    This is a piece of fragile code.
    """
    assert path[0] == "/"  #Requires absolute path
    path_parts = path.split("/")
    tarball_basename = path_parts[-3]
    sliceid = int(tarball_basename.split(".")[0].split("-")[4])
    return sliceid

def main():
    global args

    #Import the differencing scripts/utilities
    if args.with_script_path is not None:
        if os.path.isdir(args.with_script_path):
            sys.path.append(args.with_script_path)
        else:
            raise Exception("--with-script-path must be a directory.")
    #import idifference #TODO
    import rdifference
    import rx_make_database

    #Set up database

    #Table structure should be consistent with the diskprint_database repository's 00_load_diskprintdb.sql
    outconn = sqlite3.connect("registry_deltas.db")
    outcur = outconn.cursor()
    outcur.execute("""
        CREATE TABLE IF NOT EXISTS hive (
          hiveid NUMBER,
          hivepath TEXT,
          osetid TEXT,
          appetid TEXT,
          sequenceid NUMBER
        );
    """)
    outcur.execute("""
        CREATE TABLE IF NOT EXISTS regdelta (
          osetid TEXT,
          appetid TEXT,
          sequenceid NUMBER,
          sliceid NUMBER,
          hiveid NUMBER,
          cellpath TEXT,
          cellaction NUMBER,
          parentmtimebefore TEXT,
          parentmtimeafter TEXT,
          mtimebefore TEXT,
          mtimeafter TEXT,
          valuesha1before TEXT,
          valuesha1after TEXT,
          celltypebefore TEXT,
          celltypeafter TEXT,
          iskeybefore BOOLEAN,
          iskeyafter BOOLEAN,
          slicetype TEXT
        );
    """)

    #Build list of RegXML Extractor output directories
    re_dir_sequence = []
    (conn, cursor) = differ_library.db_conn_from_config_path(args.config)
    tarball_abs_paths = differ_library.tarball_sequence_from_sequence_triplet(cursor, args.sequence_id)
    logging.debug("tarball_abs_paths = %r" % tarball_abs_paths)
    for tarball_abs_path in tarball_abs_paths:
        re_abs_path = args.dwf_all_results_root + "/slice" + tarball_abs_path + "/invoke_regxml_extractor.sh"
        if not os.path.isdir(re_abs_path):
            raise Exception("Path in input file is not directory: %r." % re_abs_path)
        #TODO Test for logged success at re_abs_path + ".status.log"
        re_dir_sequence.append(re_abs_path)
    if len(re_dir_sequence) == 0:
        raise Exception("The sequence should have a non-zero number of RegXML Extractor directories.")

    logging.debug("re_dir_sequence = %r" % re_dir_sequence)

    #Establish DFXML sequences
    #TODO

    #Establish RegXML sequences
    hive_file_histories = collections.defaultdict(list)
    #For now, require the anno database
    for rd in re_dir_sequence:
        logging.debug("Inspecting \"%s\"." % rd)
        annofile_path = os.path.join(rd,"anno.db")
        checked_list_path = os.path.join(rd,"linted.txt")
        manifest_path = os.path.join(rd,"manifest.txt")
        logging.debug("Checked list path: \"%s\"." % checked_list_path)
        logging.debug("Manifest path: \"%s\"." % manifest_path)
        if os.path.isdir(rd) and not os.path.isfile(manifest_path):
            raise Exception("Manifest required (for now); manifest.txt not found in \"%s\"." % rd)
        hive_to_fspath = dict()
        with open(manifest_path, "r") as manifest_file:
            for line in manifest_file:
                #Format: Tab-delimited, seven columns; first is the hive, third the path of the hive within the image file system
                parts = line.strip().split("\t")
                if len(parts) < 3:
                    logging.warning("Got an oddly short line from the manifest file.")
                    continue
                hive_to_fspath[parts[0]] = parts[2]
        logging.debug("hive_to_fspath: %r." % hive_to_fspath)

        #Read through the successful files
        with open(checked_list_path, "r") as checked_list:
            for line in checked_list:
                #Format: Tab-delimited, two columns, first is the hive, second the RegXML of the hive
                parts = line.strip().split("\t")
                if len(parts) < 2:
                    logging.warning("Got an oddly short line from the checked-list file.")
                    continue
                hive_path = parts[0]
                regxml_path = parts[1]
                fspath = hive_to_fspath.get(hive_path)
                if fspath:
                    hive_file_histories[fspath].append(regxml_path)
                else:
                    logging.error("Could not find a path in the manifest mapping: \"%s\"." % regxml_path)
    logging.info("hive_file_histories:\n\t%r" % hive_file_histories)

    #Iterate through DFXML sequences, outputting idifference to table
    #TODO

    #Iterate through RegXML sequences broken out by image file system path
    #Output rdifference to table
    local_hiveid_counter = 0
    for hive_fspath in hive_file_histories:
        local_hiveid_counter += 1
        sequence_id_parts = differ_library.split_sequence_id(args.sequence_id)
        hiveid_record = {
          "hiveid": local_hiveid_counter,
          "hivepath": hive_fspath,
          "osetid": sequence_id_parts[0],
          "appetid": sequence_id_parts[1],
          "sequenceid": sequence_id_parts[2]
        }
        rx_make_database.insert_db(outcur, "hive", hiveid_record)
        outconn.commit()
        logging.debug("Just inserted record:\n\t%r" % hiveid_record)
        s = rdifference.HiveState(notimeline=True)
        logging.info(">> Starting hive sequence: %s" % hive_fspath)
        for (regxml_file_index, regxml_file) in enumerate(hive_file_histories[hive_fspath]):
            logging.info(">>> Reading %s" % regxml_file)
            logging.debug("local_hiveid_counter: %d" % local_hiveid_counter)
            s.process(regxml_file)
            if regxml_file_index > 0:
                # Not the first file. Output.
                logging.info(">>> Outputting")
                logging.info("\t%d\tNew cells" % len(s.new_files))
                logging.info("\t%d\tDeleted cells" % len(s.cnames.values()))
                logging.info("\t%d\tCells with changed content" % len(s.changed_content))
                logging.info("\t%d\tCells with changed properties" % len(s.changed_properties))
                logging.info("(Changed content and properties are lumped together.)")

                #Output new cells
                for cell in s.new_files:
                    #If possible, find the mtime of the parent in the old state
                    old_parent_mtime = None
                    parent_path = cell.parent_key and cell.parent_key.full_path()
                    if parent_path:
                        old_parent_cell = s.cnames.get(parent_path)
                        old_parent_mtime = time_string_from_cell(old_parent_cell)
                    regdelta_record = {
                      "osetid": hiveid_record["osetid"],
                      "appetid": hiveid_record["appetid"],
                      "sequenceid": hiveid_record["sequenceid"],
                      "sliceid": sliceid_from_regxml_path(regxml_file),
                      "hiveid": local_hiveid_counter,
                      "cellpath": cell.full_path(),
                      "cellaction": "created",
                      "parentmtimebefore": old_parent_mtime,
                      "parentmtimeafter": time_string_from_cell(cell.parent_key),
                      "mtimebefore": None,
                      "mtimeafter": time_string_from_cell(cell),
                      "valuesha1before": None,
                      "valuesha1after": cell.sha1(),
                      "celltypebefore": None,
                      "celltypeafter": cell.type(),
                      "iskeybefore": None,
                      "iskeyafter": isinstance(cell, dfxml.registry_key_object),
                      "slicetype": PLACEHOLDER_SLICE_TYPE
                    }
                    rx_make_database.insert_db(outcur, "regdelta", regdelta_record)

                #Output deleted cells
                for ocell in s.cnames.values():
                    #If possible, find the mtime of the parent in the new state
                    new_parent_mtime = None
                    parent_path = ocell.parent_key and ocell.parent_key.full_path()
                    if parent_path:
                        new_parent_cell = s.new_cnames.get(parent_path)
                        new_parent_mtime = time_string_from_cell(new_parent_cell)
                    regdelta_record = {
                      "osetid": hiveid_record["osetid"],
                      "appetid": hiveid_record["appetid"],
                      "sequenceid": hiveid_record["sequenceid"],
                      "sliceid": sliceid_from_regxml_path(regxml_file),
                      "hiveid": local_hiveid_counter,
                      "cellpath": ocell.full_path(),
                      "cellaction": "removed",
                      "parentmtimebefore": time_string_from_cell(ocell.parent_key),
                      "parentmtimeafter": new_parent_mtime,
                      "mtimebefore": time_string_from_cell(ocell),
                      "mtimeafter": None,
                      "valuesha1before": ocell.sha1(),
                      "valuesha1after": None,
                      "celltypebefore": ocell.type(),
                      "celltypeafter": None,
                      "iskeybefore": isinstance(ocell, dfxml.registry_key_object),
                      "iskeyafter": None,
                      "slicetype": PLACEHOLDER_SLICE_TYPE
                    }
                    rx_make_database.insert_db(outcur, "regdelta", regdelta_record)

                #Output cells with changed properties - including value content
                #Odd collection reasons: the changed content and changed properties dictionaries make sense in generated reporting, but not for the purposes of this table.
                #TODO The .full_path() isn't the best field to use for unique identification, as there have been bit-for-bit identical, ambiguous paths discovered in the wild.  We're _probably_ fine until malware analysis starts.
                changed_properties_noted = set()
                for changeset in [s.changed_content, s.changed_properties]:
                  for (ocell, cell) in changeset:
                    if cell.full_path() in changed_properties_noted:
                      continue
                    regdelta_record = {
                      "osetid": hiveid_record["osetid"],
                      "appetid": hiveid_record["appetid"],
                      "sequenceid": hiveid_record["sequenceid"],
                      "sliceid": sliceid_from_regxml_path(regxml_file),
                      "hiveid": local_hiveid_counter,
                      "cellpath": cell.full_path(),
                      "cellaction": "property updated",
                      "parentmtimebefore": time_string_from_cell(ocell.parent_key),
                      "parentmtimeafter": time_string_from_cell(cell.parent_key),
                      "mtimebefore": time_string_from_cell(ocell),
                      "mtimeafter": time_string_from_cell(cell),
                      "valuesha1before": ocell.sha1(),
                      "valuesha1after": cell.sha1(),
                      "celltypebefore": ocell.type(),
                      "celltypeafter": cell.type(),
                      "iskeybefore": isinstance(ocell, dfxml.registry_key_object),
                      "iskeyafter": isinstance(cell, dfxml.registry_key_object),
                      "slicetype": PLACEHOLDER_SLICE_TYPE
                    }
                    rx_make_database.insert_db(outcur, "regdelta", regdelta_record)
                    changed_properties_noted.add(cell.full_path())
            s.next()
    outconn.commit()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create a SQLite database of file system and registry differences as found by RegXML Extractor.  Meant to be run on a single sequence of disk images processed by RegXML Extractor.")
    parser.add_argument("dwf_all_results_root", help="Absolute path to the Diskprints workflow results root.")
    parser.add_argument("sequence_id", help="Identifier for the target analysis sequence, formatted as osetid-appetid-sequenceid.")
    parser.add_argument("--with-script-path", help="Directory where installed rx_make_database.py, idifference.py and rdifference.py reside.")
    parser.add_argument("--config", help="Configuration file", default="differ.cfg")
    parser.add_argument("-d", "--debug", action="store_true", help="Enable debug printing.")
    args = parser.parse_args()

    #Set up logging
    logging.basicConfig(
      format='%(asctime)s %(levelname)s: %(message)s',
      datefmt='%Y-%m-%dT%H:%M:%SZ',
      level=logging.DEBUG if args.debug else logging.INFO
    )

    main()
