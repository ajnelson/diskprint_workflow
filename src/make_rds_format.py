#!/opt/local/bin/python3.3

"""
This program takes a DFXML file and converts it to the RDS FILE Record Type.

Reference:
http://www.nsrl.nist.gov/Documents/Data-Formats-of-the-NSRL-Reference-Data-Set-16.pdf
Table 2
"""

__version__ = "0.1.1"

import os
import logging

import dfxml

def main():
    global args
    with open(args.input_dfxml, "rb") as input_fh:
        with open(args.output_file, "w", newline='\r\n') as output_fh:
            def process_fi(fi):
                if fi.name_type() != "r":
                    return
                _sha1 = '"' + (fi.sha1() or "") + '"'
                _md5 = '"' + (fi.md5() or "") + '"'
                _filename = '"' + os.path.basename((fi.filename() or "")) + '"'
                _filesize = str(fi.filesize() or "")
                print(",".join([_sha1, _md5, '""', _filename, _filesize, "", "", '""']), file=output_fh)
            dfxml.read_dfxml(xmlfile=input_fh, callback=process_fi)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("input_dfxml")
    parser.add_argument("output_file")
    parser.add_argument("-d", "--debug", help="Enable debug printing", action="store_true")
    args = parser.parse_args()

    logging.basicConfig(
      format='%(asctime)s %(levelname)s: %(message)s',
      datefmt='%Y-%m-%dT%H:%M:%SZ',
      level=logging.DEBUG if args.debug else logging.INFO
    )

    main()
