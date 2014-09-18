#!/opt/local/bin/python3.3

"""
This program takes a DFXML file and converts it to the RDS FILE Record Type.

Reference:
http://www.nsrl.nist.gov/Documents/Data-Formats-of-the-NSRL-Reference-Data-Set-16.pdf
Table 2
"""

__version__ = "0.2.5"

import os
import logging
import binascii

_logger = logging.getLogger(os.path.basename(__file__))

import Objects

def main():
    global args
    with open(args.output_file, "w", newline='\r\n') as output_fh:
        #Print header
        print('"SHA-1","MD5","CRC32","FileName","FileSize","ProductCode","OpSystemCode","SpecialCode"', file=output_fh)

        for (event, obj) in Objects.iterparse(args.input_dfxml):
            if not isinstance(obj, Objects.FileObject):
                continue

            #File must be new or modified.
            if not ("new" in obj.annos or "modified" in obj.annos):
                continue

            #File must be regular (not a directory, link, etc).
            if obj.name_type != "r":
                continue

            #File must be allocated.
            if not obj.alloc:
                continue

            #To get the CRC32, the file must not be compressed.  (The .compressed property currently denotes NTFS compression.  I haven't checked to see if this is extractable.  So for now, skip compressed files.)
            if obj.compressed:
                _logger.info("Skipping a file stored with NTFS compression (id=%r)." % obj.id)
                continue

            _sha1 = ('"' + (obj.sha1 or "") + '"').upper()
            _md5 =  ('"' + (obj.md5  or "") + '"').upper()
            _filename = '"' + os.path.basename(obj.filename or "") + '"'
            _filesize = str(obj.filesize or "")

            _crc32 = '""'
            if obj.filesize > 0 and obj.data_brs:
                crc = 0
                try:
                    for byte_buffer in obj.data_brs.iter_contents(args.input_disk_image):
                        crc = binascii.crc32(byte_buffer, crc)
                    #This line c/o: https://docs.python.org/3.3/library/binascii.html#binascii.crc32
                    _crc32 = '"{:#010x}"'.format(crc & 0xffffffff)[3:].upper()
                except:
                    _logger.info("Input DFXML file: %r." % os.path.abspath(args.input_dfxml))
                    _logger.info("File ID: %r." % obj.id)
                    _logger.info("Object: %r." % obj)
                    raise

            print(",".join([_sha1, _md5, _crc32, _filename, _filesize, "", "", '""']), file=output_fh)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("input_dfxml")
    parser.add_argument("input_disk_image")
    parser.add_argument("output_file")
    parser.add_argument("-d", "--debug", help="Enable debug printing", action="store_true")
    args = parser.parse_args()

    logging.basicConfig(
      format='%(asctime)s %(levelname)s: %(message)s',
      datefmt='%Y-%m-%dT%H:%M:%SZ',
      level=logging.DEBUG if args.debug else logging.INFO
    )

    main()
