#!/opt/local/bin/python3.3

"""
This program takes a DFXML file and converts it to the RDS FILE Record Type.

Reference:
http://www.nsrl.nist.gov/Documents/Data-Formats-of-the-NSRL-Reference-Data-Set-16.pdf
Table 2
"""

__version__ = "0.3.3"

import os
import logging
import binascii
import hashlib

_logger = logging.getLogger(os.path.basename(__file__))

import Objects

def main():
    global args

    checker_do = Objects.DFXMLObject()
    _appender = checker_do

    with open(args.output_file, "w", newline='\r\n') as output_fh:
        #Print header
        print('"SHA-1","MD5","CRC32","FileName","FileSize","ProductCode","OpSystemCode","SpecialCode"', file=output_fh)

        for (event, obj) in Objects.iterparse(args.input_dfxml):
            if isinstance(obj, Objects.VolumeObject):
                if event == "start":
                    checker_do.append(obj)
                    _appender = obj
                else:
                    _appender = checker_do
            elif not isinstance(obj, Objects.FileObject):
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

            #As this is a hash reference set, skip if Fiwalk had produced no hash.
            if obj.sha1 in [None, ""]:
                continue

            #Skip 0-sized NTFS $Secure system file, which is hashed by some tools (including Fiwalk) with a hard-coded rule to get its Alternate Data Stream.
            #(Accessing the same data is waiting on an update to the DFXML language.)
            if obj.filename == "$Secure" and obj.filesize == 0:
                continue

            #Currently, to get the CRC32, the file must not be compressed.  (The .compressed property currently denotes NTFS compression.  I haven't checked to see if this is extractable.  So for now, skip compressed files.)
            if obj.compressed:
                _logger.info("Skipping a file stored with NTFS compression (id=%r)." % obj.id)
                continue

            checker_fo = Objects.FileObject()
            any_error = None

            _sha1 = ('"' + (obj.sha1 or "") + '"').upper()
            _md5 =  ('"' + (obj.md5  or "") + '"').upper()
            _filename = '"' + os.path.basename(obj.filename or "") + '"'
            _filesize = str(obj.filesize or "")

            _crc32 = '""'
            if obj.filesize > 0 and obj.data_brs:
                crc = 0
                read_bytes = 0
                try:
                    #Accumulate the file data to test checksums
                    checker_md5 = hashlib.md5()
                    checker_sha1 = hashlib.sha1()

                    for byte_buffer in obj.data_brs.iter_contents(args.input_disk_image):
                        crc = binascii.crc32(byte_buffer, crc)
                        checker_md5.update(byte_buffer)
                        checker_sha1.update(byte_buffer)
                        read_bytes += len(byte_buffer)

                    #This line c/o: https://docs.python.org/3.3/library/binascii.html#binascii.crc32
                    _crc32 = '"{:#010x}"'.format(crc & 0xffffffff)[3:].upper()

                    checker_md5_digest = checker_md5.hexdigest().upper()
                    if (not _md5 in [None, "", '""']) and checker_md5_digest != _md5[1:-1]:
                        checker_fo.md5 = checker_md5_digest
                        checker_fo.diffs.add("md5")
                        any_error = True
                    checker_sha1_digest = checker_sha1.hexdigest().upper()
                    if (not _sha1 in [None, "", '""']) and checker_sha1_digest != _sha1[1:-1]:
                        checker_fo.sha1 = checker_sha1_digest
                        checker_fo.diffs.add("sha1")
                        any_error = True
                    checker_fo.filesize = read_bytes #Show read filesize regardless of a mismatch
                    if obj.filesize != read_bytes:
                        checker_fo.diffs.add("filesize")
                        any_error = True
                    if any_error:
                        _logger.error("Content mismatch between what Fiwalk computed and what this script could extract (id=%r)." % obj.id)
                        checker_fo.original_fileobject = obj
                        _appender.append(checker_fo)
                except:
                    _logger.info("Input DFXML file: %r." % os.path.abspath(args.input_dfxml))
                    _logger.info("File ID: %r." % obj.id)
                    _logger.info("Object: %r." % obj)
                    raise

            print(",".join([_sha1, _md5, _crc32, _filename, _filesize, "", "", '""']), file=output_fh)

    if args.dfxml_read_error_manifest:
        with open(args.dfxml_read_error_manifest, "w") as fh:
            checker_do.print_dfxml(fh)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("input_dfxml")
    parser.add_argument("input_disk_image")
    parser.add_argument("output_file")
    parser.add_argument("-d", "--debug", help="Enable debug printing", action="store_true")
    parser.add_argument("--dfxml-read-error-manifest", help="Optional DFXML output for read errors (determined by mismatched checksums).")
    args = parser.parse_args()

    logging.basicConfig(
      format='%(asctime)s %(levelname)s: %(message)s',
      datefmt='%Y-%m-%dT%H:%M:%SZ',
      level=logging.DEBUG if args.debug else logging.INFO
    )

    main()
