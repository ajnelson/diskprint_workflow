#!/opt/local/bin/python2.7

__version__ = "0.0.1"

import os
import sys
import argparse
import logging

import dfxml
import differ_library

def main():
    filemetadata_out = open("filemetadata.sql", "w")
    md5_out = open("md5.sql", "w")

    (conn, cursor) = differ_library.db_conn_from_config_path(args.config)

    #Get slice hash
    cursor.execute("SELECT slicehash FROM diskprint.storage WHERE location = %s", (args.slice_path,))
    inrows = [row for row in cursor]
    if len(inrows) != 1:
        logging.error("Could not find diskprint from tarball path: %r." % args.slice_path)
        sys.exit(1)
    slicehash = inrows[0]["slicehash"]

    def process_fi(fi):
        """
        Produce SQL records for every allocated file.
        (This is an inline function so the value of 'slicehash' is in scope.)
        """
        #Only allocated, regular files
        if not fi.allocated():
            return
        if fi.name_type() != "r":
            return

        #Build SQL templates
        md5_insert_template = "insert into diskprint.MD5 values ('%(keyhash)s','%(keyhash_md5)s');\n"
        filemetadata_insert_template = "insert into diskprint.filemetadata (keyhash, slicehash, path, filename, extension, bytes, mtime, ctime) values ('%(keyhash)s','%(slicehash)s','%(path)s','%(filename)s','%(extension)s',%(bytes)d,'%(mtime)s','%(ctime)s');\n"

        #Build SQL values as substitution dictionary
        d = dict()
        d["keyhash"] = fi.sha1()
        d["keyhash_md5"] = fi.md5()
        d["slicehash"] = slicehash
        d["path"] = fi.filename()
        d["filename"] = os.path.basename(fi.filename())
        d["extension"] = os.path.splitext(fi.filename())[1]
        d["bytes"] = fi.filesize()
        d["mtime"] = fi.mtime()
        d["ctime"] = fi.crtime() #TODO What does this table actually mean by ctime?  Change, or create?

        #Output
        filemetadata_out.write(filemetadata_insert_template % d)
        md5_out.write(md5_insert_template % d)

    #Begin loop through XML
    dfxml.read_dfxml(xmlfile=open(args.fiwalk_xml, "rb"), callback=process_fi)

if __name__ == "__main__":
    script_path = os.path.abspath(sys.argv[0])

    parser = argparse.ArgumentParser()
    parser.add_argument("slice_path", help="Absolute path to disk slice tarball; must exist in slices table.")
    parser.add_argument("fiwalk_xml", help="Path to Fiwalk XML output.")
    parser.add_argument("--config", help="Configuration file", default="differ.cfg")
    parser.add_argument("-d", "--debug", help="Turn on debug-level logging.", action="store_true", dest="debug")
    args = parser.parse_args()

    loglvl = logging.DEBUG if args.debug else logging.INFO
    logging.basicConfig(
      format='%(asctime)s %(levelname)s: %(message)s',
      datefmt='%Y-%m-%dT%H:%M:%SZ',
      level=loglvl
    )

    main()
