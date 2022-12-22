# Help classes to read global, private configuration , translation etc.

nx::Class create oodz_conf_global -superclass oodz_superclass {
	:variable instance:object

	:public object method create {args} {
		return [expr {[info exists :instance] ? ${:instance} : [set :instance [next]]}]
	}
	
	:method init {} {
		: read_config
		# : read_dz_conf
		# : load_dz_procs
		# : load_trns
	}

	
	:public method read_config {} {
		oodzLog notice "OODZ READING CONFIG: [file join ${:path} ../ conf daidze.ini]"
		set config_file [file join ${:path} ../ conf daidze.ini]
		set ini_handler [::ini::open $config_file]
		namespace eval ${:srv} {}
		foreach section [::ini::sections $ini_handler ] {
			foreach key [::ini::keys $ini_handler $section] {
				set var [join "${:srv} ${key}" "::"]
				if {[info exists $var] == 0} {
					ns_log Notice "SETTING $var [::ini::value $ini_handler $section $key]"
					set $var [::ini::value $ini_handler $section $key]
				} else {
					if {"[::ini::value $ini_handler $section $key]" ne "[set $var]"} {
						set $var [::ini::value $ini_handler $section $key]
					}
				}
			}
		}
		::ini::close $ini_handler
	}
}


nx::Class create oodz {	
	:method init {} {
		set :srv [ns_info server]
		set :root [file tail [file dirname [ns_pagepath]]]
		set :path [ns_pagepath]
		: read_config
		: read_dz_conf
		: load_dz_procs
		: load_trns
	}
	
	:public method inf {args} {
		switch [lindex $args 0] {
			srv {
				return ${:srv}
			}
			root {
				return ${:root}
			}
			path {
				return ${:path}
			}
			default {
				return [dict create srv ${:srv} root ${:root} path ${:path}]
			}
		}
	}
	
	:public method read_config {} {
		ns_log Notice "OODZ READING CONFIG"
		set config_file [file join ${:path} ../ conf daidze.ini]
		set ini_handler [::ini::open $config_file]
		namespace eval ${:srv} {}
		foreach section [::ini::sections $ini_handler ] {
			foreach key [::ini::keys $ini_handler $section] {
				set var [join "${:srv} ${key}" "::"]
				if {[info exists $var] == 0} {
					set $var [::ini::value $ini_handler $section $key]
				} else {
					if {"[::ini::value $ini_handler $section $key]" ne "[set $var]"} {
						set $var [::ini::value $ini_handler $section $key]
					}
				}
			}
		}
		::ini::close $ini_handler
	}
	
	:public method read_dz_conf {} {
		ns_log Notice "OODZ READING DZ CONFIG"
		foreach line [dict values [select_all dz_conf *]] {
			set [join "${:srv} [dict get $line var]" "::"] [dict get $line val]
		}
	}
	
	:public method load_dz_procs {} {
		ns_log Notice "OODZ LOADING PROCS"
		set folders [glob -nocomplain -directory [file join ${:path} [set ${:srv}::mod_dir]] *]
		ns_log Notice "FOLDERS: $folders"
		foreach f $folders {
			set ::f $f
			namespace eval [file tail $f] {
				if {[catch {set files [glob -directory [file join $::f] *.tcl]} errmsg]} {
					puts "$errmsg"
				} else {
					set files [glob -directory [file join $::f] *.tcl]
					foreach file $files {
						source $file
					}
				}
			}
		}
	}
	
	# Load Global Translations
	:public method load_trns {args} {
		msgcat::mclocale [set ${:srv}::language]
		set lang_path [file join ${:path} [set ${:srv}::lang_dir]]
		msgcat::mcload $lang_path
	}
}

# oodz create dz_obj