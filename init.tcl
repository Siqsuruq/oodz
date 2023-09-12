package require nx
package require nsf
package require dicttool
package require csv
package require textutil
package require inifile
package require msgcat

# Load OODZ Framework source files, sources from specific folder in alphabetical order. Do not change Modules order!!!
set lib_shared [ns_library shared]
set oodzFrameworkModules [list base db conf ui rest dateTime helpers]
foreach oodzModule $oodzFrameworkModules {
	puts "OODZ MODULE: $oodzModule"
	set sourceFiles	[lsort -dictionary [glob -nocomplain -directory [file join $lib_shared oodz/${oodzModule}] *.tcl]]
	foreach sourceFile $sourceFiles {
		puts "SOURCE >>>>>>>> $sourceFile"
		source $sourceFile
	}
}

# Create Startup Objects:
::oodz::log create ::oodzLog
::oodz::db create ::db
db copy dbj
dbj configure -result_format J
db copy dbl
dbl configure -result_format L
::oodz::conf create ::oodzConf -db ::db
::oodz::Session create ::ns_session
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

ns_register_proc GET /process_form process_form GET
ns_register_proc POST /process_form process_form POST




ns_runonce {
	load_dz_procs
}

