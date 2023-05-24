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
	set sourceFiles	[lsort -dictionary [glob -nocomplain -directory [file join $lib_shared oodz/${oodzModule}] *]]
	foreach sourceFile $sourceFiles {
		puts "SOURCE >>>>>>>> $sourceFile"
		source $sourceFile
	}
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


