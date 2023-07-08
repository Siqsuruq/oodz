proc process_form {args} {
	set m [ns_conn method]
	set r [ns_getform]
	set data [dict create]
	if {$m eq "GET"} {
		dict set data module [ns_set iget $r mod "base"]
		dict set data xml [ns_set iget $r xml ""]
	} elseif {$m eq "POST"} {
		set dd [ns_set array $r]
		set dz_cmd [dict getnull $dd dz_cmd]
		if {$dz_cmd ne ""} {
			$dz_cmd [dict unset dd dz_cmd]
		}
	}
	return $data
}

proc load_dz_procs {args} {
	set folders [glob -nocomplain -directory [file join [ns_pagepath] [::oodzConf get_global mod_dir]] *]
	foreach f $folders {
		set ::f $f
		namespace eval [file tail $f] {
			if {[catch {set files [glob -directory [file join $::f] *.tcl]} errmsg]} {
				puts "$errmsg"
			} else {
				set files [glob -directory [file join $::f] *.tcl]
				foreach file $files {
					if {[regexp {Class.tcl} $file] == 1} {
						load_oodz_class $file
					} else {
						source $file
					}
				}
			}
		}
	}
}

# If filename ends with *Class.tcl loads in global namespace
proc load_oodz_class {args} {
	source [lindex $args 0]
}