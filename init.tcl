package require nx
package require nsf
package require dicttool

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