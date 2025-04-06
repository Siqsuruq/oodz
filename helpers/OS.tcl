namespace eval oodz {
    ::nx::Object create osObj {
        # Returns the list of files in a directory with the specified extension
        # If no extension is specified, it returns all files
        :public object method list_files {dir_name {file_ext ""}} {
            set result ""
            if {[llength $file_ext] ne 0} {
                foreach ext $file_ext {
                    set f_l [glob -nocomplain -dir $dir_name *$ext]
                    if {[llength $f_l] != 0} {
                        foreach f $f_l {
                            lappend result [file tail $f]
                        }
                    }	
                }
            } else {
                set f_l [glob -nocomplain -dir $dir_name *]
                if {[llength $f_l] != 0} {
                    foreach f $f_l {
                        lappend result [file tail $f]
                    }
                }
            }
            return [lsort -dictionary $result]
        }
    }
}