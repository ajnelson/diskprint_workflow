#!/usr/bin/env python

from cybox.common import Hash, String, MeasureSource
from cybox.common import ToolType, ToolInformation, ToolInformationList
from cybox.core import Observable, Observables
from cybox.core import Action, Actions, Event
from cybox.core import AssociatedObject, AssociatedObjects, AssociationType
from cybox.objects.file_object import File
import cybox.utils
import csv
import sys

def main():
    print '<?xml version="1.0" encoding="UTF-8"?>'
    lst = []
    obj_dict = {}
    #Open the RDS formatted files and read in the fields of interest.
    with open(sys.argv[1], 'r') as csvfile:
        for row in csv.reader(csvfile,delimiter=','):
            SHA1 = row[0]
            MD5 = row[1]
            #CRC32 = row[2]
            filename = row[3]
            filesize = row[4]       
#assigning a namespace.              
            NS = cybox.utils.Namespace("http://ncsl.nist.gov/", "NSRL_RDS")
            cybox.utils.set_id_namespace(NS)
    
#pass in the hash value. Type is determined by the hash value size
            md5 = Hash(MD5)
            sha1 = Hash(SHA1)
    
#crc32 type needs to be explicitly defined. 
            #crc32 = Hash(CRC32, exact=True)
            #crc32.type_ = String("CRC32")

# List of supported cybox file metadata. This is my template of supported features.
            #f = File()
            # f.file_name = filename
            #f.file_path = "FILE_PATH"
    
            #f.file_extension = "EXE"
            #f.device_path = "DEVICE_PATH"
            #f.full_path = "FULL_PATH"
            #f.magic_number = 11
            #f.file_format = "TXT"
            #f.add_hash(md5)
            #f.add_hash(sha1)
            #f.add_hash(crc32)
            #f.modified_time = "MODIFIED_TIME"
            #f.accessed_time = "ACCESSED_TIME"
            #f.created_time = "06/15/2009 1:45pm"

#Not supported in the file object class when I wrote this code..
            # - Digital_Signatures
            # - File_Attributes_List
            # - Permissions
            # - User_Owner
            # - Packer_List
            # - Peak_Entropy
            # - Sym_Links
            # - Extracted_Features
            # - Byte Runs

            # check that the filesize in the csv file is greater than 0. 
            # build the file object with RDS type data.
            if len(filesize) > 0:
                f = File()
                f.file_name = filename
                f.size_in_bytes = filesize
                f.add_hash(md5)
                f.add_hash(sha1)

#Store the file objects in an array
                lst.append(f)
            #count = len(lst)

    lstlen = len(lst)

# may have to set start of list to 1 to skip the header line in an RDS file.
# set to print out 25 lines in the sample RDS file as cybox file objects.
    
    #fileoutnum = lst[0:lstlen]
    fileoutnum = lst[0:25]

    #o = Observable(f)
    #o.description = "This observable specifies a specific file observation."

 #Tool object definition 
    tt = ToolType()
    t = ToolInformation()
    t.name = "RDS metadata"
    t.description = String("NIST NSRL RDS File metadata")
    t.vendor = "NIST NSRL"
    t.version = "None"
    ta = ToolInformationList(t)
      
    ms = MeasureSource()
    ms.name = "Tool Output"
    ms.toolType= tt
    ms.tools = ta
 
# Action is execute Tool
    a = Action()
    a.name = "Generate RDS metadata in xml."
    a.action_status = "Success"
       
    ao = AssociatedObject()
    ao.association_type = AssociationType("Affected")
# Links the file objects to the associated object.
    a.associated_objects = AssociatedObjects(fileoutnum)

    e = Event()
    e.observation_method = ms
    e.actions = Actions([a])

    print Observables(e).to_xml()
    #print Observables(o).to_xml()

if __name__ == "__main__":
    main()
