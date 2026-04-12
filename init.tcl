#source [file join [ns_serverpath] lib/chilkat/chilkat.tcl]
source [file join [ns_library shared] oodz/packages.tcl]

::nx::Slot eval {
	:method type=uuid {name value} {
		set pattern {^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$}
		if {![regexp $pattern $value]} {
			error "Value '$value' of parameter $name is not UUID"
		}
		return $value
	}
}
::Serializer exportMethods {
    ::nx::Slot method type=uuid
}

# Load OODZ Framework source files, sources from specific folder in alphabetical order. Do not change Modules order!!!
set oodzFrameworkModules [list base db conf ui rest dateTime helpers crypto session fileStorage mop]
# set oodzFrameworkModules [list base db conf rest dateTime helpers crypto session fileStorage]
foreach oodzModule $oodzFrameworkModules {
	set sourceFiles	[lsort -dictionary [glob -nocomplain -directory [file join [ns_library shared] oodz/${oodzModule}] *.tcl]]
	foreach sourceFile $sourceFiles {
		source $sourceFile
	}
}

try {
	# Create Startup Objects:
	::oodz::db create ::db
	db copy dbj
	dbj configure -result_format J
	db copy dbl
	dbl configure -result_format L
	::oodz::conf create ::oodzConf

	# Creating ::oodzSession Global Object (File)
	sessionFactory createSession -persist_type ::oodz::SessionFile
	::oodz::htmlWrapper create ::oodzhtmlWrapper -conf ::oodzConf -db ::db
	::oodz::dateTime create ::oodzTime -oodzConf ::oodzConf
	::oodz::fileStorage create ::fileStorage
} on error {errMsg} {
	ns_log Error "Startup objects creation error: $errMsg"
}


# Get API Version from configuration, if there is no such ns_param set it to "v1"
set api_version [ns_config ns/server/[ns_info server]/module/oodz api_version ""]
if {$api_version eq ""} {
	set api_version "v1"
}

proc apiincall {args} {
	[apiin new -reqType [ns_conn method] -url [ns_conn url] -ssl [ns_conn driver] -api_version v2] answer_request
}

# Register proc handlers for GET,POST,PUT and DELETE requests
foreach method {GET POST PUT DELETE} {
	ns_register_proc $method api/$api_version apiincall $api_version
}

ns_register_proc GET /handle_form handle_form GET
ns_register_proc POST /handle_form handle_form POST

proc load_dz_procs {args} {
	set folders [glob -nocomplain -directory [file join [ns_pagepath] [::oodzConf get_global mod_dir]] *]
	foreach f $folders {
		set ::f $f
		set ns ::[file tail $f]
		namespace eval $ns {
			if {[catch {set files [glob -directory [file join $::f] *.tcl]} errmsg]} {
				ns_log Error "Error loading OODZ procs from folder $f: $errmsg"
			} else {
				set files [lsort -dictionary [glob -directory [file join $::f] *.tcl]]
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

ns_runonce {
	load_dz_procs
	ns_log Error "------------------- MUAEHEHE ----------------------------"
}

# Translation initialization
set lang_path [file join [ns_server pagedir] [::oodzConf get_global lang_dir]]
ns_ictl trace create [subst {
	source [file join [ns_library shared] oodz/packages.tcl]
    ::msgcat::mcload {$lang_path}
}]