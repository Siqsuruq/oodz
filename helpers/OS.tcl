namespace eval oodz {
    ::nx::Object create osObj {
        # Returns the list of files in a directory with the specified extension
        # If no extension is specified, it returns all files
        :public object method list_files {dir_name {file_ext ""}} {
            set result ""
            if {$file_ext ne ""} {
                foreach ext $file_ext {
                    foreach f [glob -nocomplain -dir $dir_name *$ext] {
                        if {[file isfile $f]} {
                            lappend result [file tail $f]
                        }
                    }
                }
            } else {
                foreach f [glob -nocomplain -dir $dir_name *] {
                    if {[file isfile $f]} {
                        lappend result [file tail $f]
                    }
                }
            }
            return [lsort -dictionary -unique $result]
        }

        # Returns a sorted list of subdirectories in a directory.
        :public object method list_dirs {dir_name} {
            set result ""
            foreach f [glob -nocomplain -dir $dir_name *] {
                if {[file isdirectory $f]} {
                    lappend result [file tail $f]
                }
            }
            return [lsort -dictionary $result]
        }
    }
}