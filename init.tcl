package require nx
package require nsf
package require dicttool
package require csv
package require textutil
package require inifile
package require msgcat
package require uuid
package require fileutil
package require hrfilesize


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
set lib_shared [ns_library shared]
set oodzFrameworkModules [list base db conf ui rest dateTime helpers crypto session fileStorage]
# set oodzFrameworkModules [list base db conf rest dateTime helpers crypto session fileStorage]
foreach oodzModule $oodzFrameworkModules {
	
	set sourceFiles	[lsort -dictionary [glob -nocomplain -directory [file join $lib_shared oodz/${oodzModule}] *.tcl]]
	foreach sourceFile $sourceFiles {
		source $sourceFile
	}
}

# Create Startup Objects:
::oodz::db create ::db
db copy dbj
dbj configure -result_format J
db copy dbl
dbl configure -result_format L
::oodz::conf create ::oodzConf -db ::db

# Creating ::oodzSession Global Object (File)
sessionFactory createSession -persist_type ::oodz::SessionFile

::oodz::htmlWrapper create ::oodzhtmlWrapper -conf ::oodzConf -db ::db
::oodz::dateTime create ::oodzTime -oodzConf ::oodzConf


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
		namespace eval [file tail $f] {
			if {[catch {set files [glob -directory [file join $::f] *.tcl]} errmsg]} {
				puts "$errmsg"
			} else {
				set files [glob -directory [file join $::f] *.tcl]
				foreach file $files {
					if {[regexp {Class.tcl} $file] == 1} {
						load_oodz_class $file
					} else {
						puts "CURRENT NAMESPACE [namespace current] --> $file"
						source $file
					}
				}
			}
		}
	}
}

# If filename ends with *Class.tcl loads in global namespace
proc load_oodz_class {args} {
	puts "CURRENT NAMESPACE [namespace current] --> [lindex $args 0]"
	source [lindex $args 0]
}

ns_runonce {
	load_dz_procs
}

