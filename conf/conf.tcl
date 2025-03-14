namespace eval oodz {
	nx::Class create conf -superclass baseClass -mixins superClass {
		:property {db:object,required}
		:property {conf_file "default.ini"}
		
		:method init {} {
			: read_config
			: read_dz_conf
			: load_trns
		}

		# Load config options from default.ini
		:public method read_config {args} {
			set config_file [file join ${:srvpath} ../ conf ${:conf_file}]
			set ini_handler [::ini::open $config_file]
			foreach section [::ini::sections $ini_handler ] {
				foreach key [::ini::keys $ini_handler $section] {
					[self] add [dict create $key [::ini::value $ini_handler $section $key]]
				}
			}
			::ini::close $ini_handler
		}
		
		# Load config options from database
		:public method read_dz_conf {args} {
			foreach line [${:db} select_all dz_conf *] {
				puts $line
				[self] add [dict create [dict get $line var] [dict get $line val]]
			}
		}
		
		# Load Global Translations
		:public method load_trns {args} {
			try {
				set lang_path [file join ${:srvpath} [[self] get lang_dir L]]
				set lang [[self] get language L]
				load_trns_file $lang $lang_path
				return -code ok
			} on error {msg} {
				return -code error "Error loading translations: $msg"
			}
		}
		
		# Method to retrieve config option value
		:public method get_global {var_name} {
			return [[self] $var_name get]
		}
		
		:public method load_dz_procs {args} {
			set folders [glob -nocomplain -directory [file join ${:srvpath} [: get_global mod_dir]] *]
			foreach f $folders {
				set module_namepace [file tail $f]
				set files [glob -nocomplain -directory $f *.tcl]
				foreach file $files {
					if {[regexp {Class.tcl} $file] == 1} {
						source $file
					} else {
						namespace eval $module_namepace [list ::source $file]
					}
				}
			}
		}
		
		:public method reload {args} {
			: read_dz_conf
			: load_trns
		}
	}
}

