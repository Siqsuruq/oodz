namespace eval oodz {
	nx::Class create conf -superclass baseClass -mixins superClass {
		:property {conf_table "dz_conf"}
		:property {conf_file "default.ini"}
		
		:variable instance:object

		:public object method create {args} {
    		return [expr {[info exists :instance] ? ${:instance} : [set :instance [next]]}]
		}

		:method init {} {
			: read_config
			: read_dz_conf
			: load_trns
		}

		# Load config options from default.ini
		:public method read_config {args} {
			::oodzLog error "Loading configuration from file ${:conf_file}..."
			set config_file [file join ${:srvpath} ../ conf ${:conf_file}]
			set ini_handler [::ini::open $config_file]
			foreach section [::ini::sections $ini_handler ] {
				foreach key [::ini::keys $ini_handler $section] {
					[self] add [dict create $key [::ini::value $ini_handler $section $key]]
				}
			}
			::ini::close $ini_handler
		}
		
		# Load config options from database table
		:public method read_dz_conf {args} {
			::oodzLog error "Loading configuration from database table ${:conf_table}..."
			foreach line [::db select_all ${:conf_table} *] {
				[self] add [dict create [dict get $line var] [dict get $line val]]
			}
		}

		# Write config options to database table
		:public method write_dz_conf {args} {
			try {
				foreach module [dict keys [lindex $args 0]] {
					set config_data [dict get [lindex $args 0] $module]
					foreach var [dict keys $config_data] {
						set res [lindex [::db select_all ${:conf_table} {id val} "module=[ns_dbquotevalue $module] AND var=[ns_dbquotevalue $var]" list] 0]
						set id [dict get $res id]
						set rval [dict get $res val]
						if {$rval ne [dict get $config_data $var]} {
							set upd_val [dict create id $id module $module var $var val [dict get $config_data $var]]
							::db update_all ${:conf_table} $upd_val
						}
					}
				}
				:reload
				return -code ok
			} on error {errMsg} {
				return -code error "Error writing config: $errMsg"
			}
		}
		
		:method load_trns_file {args} {
			set lang [lindex $args 0]
			set lang_path [lindex $args 1]
			::msgcat::mclocale $lang
			::msgcat::mcload $lang_path
		} 

		# Load Global Translations
		:public method load_trns {args} {
			::oodzLog error "Loading translations..."
			try {
				set lang_path [file join ${:srvpath} [[self] get lang_dir L]]
				set lang [[self] get language L]
				: load_trns_file $lang $lang_path
				return -code ok
			} on error {errMsg} {
				return -code error "Error loading translations: $errMsg"
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
		
		# New Module-specific configuration methods
		# New method to retrieve list of modules with configuration options
		:public method modules {args} {
			try {
				set modules_list [list]
				foreach line [::db select_all ${:conf_table} module] {
					set module [dict get $line module]
					if {$module ne "" && [lsearch -exact $modules_list $module] == -1} {
						lappend modules_list $module
					}
				}
				return $modules_list
			} on error {errMsg} {
				return -code error "Error retrieving modules: $errMsg"
			}
		}
		:public method module_exists {args} {
			set module [lindex $args 0]
			try {
				set res [::db select_all ${:conf_table} module "module=[ns_dbquotevalue $module]" list]
				return [expr {[llength $res] > 0}]
			} on error {errMsg} {
				return -code error "Error checking module existence: $errMsg"
			}
		}
		# New method to retrieve configuration options for a specific module, with optional filtering by option name
		:public method get_module_config {args} {
			set input [lindex $args 0]
			if {$input eq ""} {
				return -code error "Error: module or configuration path is required"
			}
			# Split the input by the dot character
			set path [split $input "."]
			set module [lindex $path 0]
			set var_filter [lindex $path 1]
			try {
				set module_config [dict create]
				set where_clause "module=[ns_dbquotevalue $module]"
				# Optimize query if a specific option path is requested
				if {$var_filter ne ""} {
					append where_clause " AND var=[ns_dbquotevalue $var_filter]"
				}
				foreach line [::db select_all ${:conf_table} * $where_clause list] {
					dict set module_config [dict get $line var] [dict get $line val]
				}
				# Return only the option value if a dot notation was used
				if {$var_filter ne ""} {
					if {[dict exists $module_config $var_filter]} {
						return [dict get $module_config $var_filter]
					}
					return "" ;# Return empty string if option does not exist
				}
				return $module_config
			} on error {errMsg} {
				return -code error "Error retrieving module config: $errMsg"
			}
		}
		
		:public method write_module_config {args} {
			set input [lindex $args 0]
			set value [lindex $args 1]
			if {$input eq ""} {
				return -code error "Error: module or configuration path is required"
			}
			# Split the input by the dot character
			set path [split $input "."]
			set module [lindex $path 0]
			set var [lindex $path 1]
			try {
				set res [lindex [::db select_all ${:conf_table} {id val} "module=[ns_dbquotevalue $module] AND var=[ns_dbquotevalue $var]" list] 0]
				if {[dict exists $res id]} {
					set id [dict get $res id]
					set upd_val [dict create id $id module $module var $var val $value]
					::db update_all ${:conf_table} $upd_val
				} else {
					set ins_val [dict create module $module var $var val $value]
					::db insert_all ${:conf_table} $ins_val
				}
				:reload
				return -code ok
			} on error {errMsg} {
				return -code error "Error writing module config: $errMsg"
			}
		}


		:public method reload {args} {
			::oodzLog error "Reloading configuration and translations..."
			: read_dz_conf
			: load_trns
		}
	}
}

