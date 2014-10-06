#!/usr/bin/env python

#Create a cybox Volume Object

from cybox.common import Hash, String
from cybox.core import Observable, Observables
from cybox.objects.volume_object import Volume, FileSystemFlagList
import cybox.utils


def main():
    print '<?xml version="1.0" encoding="UTF-8"?>'
  #Volume object definition
    v = Volume()
    fsfl = FileSystemFlagList()
    
    v.name = "NAME"
    v.device_path = "DEVICE_PATH"
    v.file_system_type = "FILE_SYSTEM_TYPE"
    v.total_allocation_units = 2048
    v.sectors_per_allocation_unit = 512
    v.bytes_per_sector = 512
    v.actual_available_allocation_units = 512
    v.creation_time = "06/15/2009 1:45pm"
    #v. file_system_flag_list = fsfl
    v.serial_number = "4"
    o = Observable(v)
    o.description = "This observable specifies a specific volume observation."

    print Observables(o).to_xml()

if __name__ == "__main__":
    main()
