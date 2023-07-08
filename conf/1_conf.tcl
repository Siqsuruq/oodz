namespace eval oodz {
	nx::Class create conf -superclass baseClass {
		:property {db:object,required}
		:property {conf_file "default.ini"}
		
		:method init {} {
			: read_config
			: read_dz_conf
			: load_trns
		}

		# Load config options from default.ini
		:public method read_config {args} {
			set config_file [file join ${:path} ../ conf ${:conf_file}]
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
				[self] add [dict create [dict get $line var] [dict get $line val]]
			}
		}
		
		# Load Global Translations
		:public method load_trns {args} {
			msgcat::mclocale [[self] get data language L]
			set lang_path [file join ${:path} [[self] get data lang_dir L]]
			msgcat::mcload $lang_path
		}
		
		# Method to retrieve config option value
		:public method get_global {var_name} {
			return [dict getnull ${:obj_data} $var_name]
		}
		
		:public method load_dz_procs {args} {
			set folders [glob -nocomplain -directory [file join ${:path} [: get_global mod_dir]] *]
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
		
		:public method relaod {args} {
			: read_dz_conf
			: load_trns
		}
	}
}

::oodz::conf create ::oodzConf -db ::db