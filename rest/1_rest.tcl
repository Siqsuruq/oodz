# This is main Routing/Endpoint class, it defines the routing logic for REST API
# 1. Extracts any necessary data from the request (such as path parameters, query parameters, or the request body),
# 2. Calls the appropriate service method(s) to perform the required business logic,
# 3. Constructs the HTTP response to send back to the client.

nx::Class create apiin -superclass ::oodz::superClass {
	:property reqType:required
	:property url:required
	:property ssl:required
	:property api_version:required
	:variable error_codes [dict create 400 "Bad request" 401 "Unauthorized" 403 "Forbidden" 404 "Resource not found" 405 "Method not allowed" 413 "Request Entity Too Large" 418 "I'm a teapot" 500 "Internal server error"]
	:variable redirect_codes [dict create 301 "Moved Permanently" 302 "Moved temporarily" 303 "See Other" 304 "Not Modified" 307 "Temporary Redirect" 308 "Permanent Redirect"]

	:method init {} {
		set :obj_answer_content_type "application/json"
		
		set :obj_header [ns_conn headers]
		oodzLog notice "************ V2 API CALL ******************"
		oodzLog notice "METHOD: ${:reqType} - URL: ${:url}"
		oodzLog notice "HEADER: [ns_set array ${:obj_header}]"
	}
	
	:public method answer_request {args} {
		if {[[self] cget -ssl] ne "nsssl"} {
			oodzLog warning "HTTP Requests are Not Safe, please use HTTPS"
		}
		set surl [[self] split_url]
		set resource [lindex $surl 3]

		#Check if resource folder exists and if it has API proc
		if {[file isdirectory [file join ${:srvpath} [oodzConf get_global mod_dir] $resource]] == 1 && [::oodz::api info instances ::${resource}::Api] ne ""} {
			set values [lrange $surl 4 end]
			set params [: get_body]
			# puts "REQUEST: ${:reqType} VALUES: $values PARAMS: $params"
			if {$params != 0} {
				# Execute call and get result list.
				set result [::${resource}::Api dispatcher ${:reqType} $values $params ${:url}]
				: answer $result
			}
		} else {
			oodzLog notice "API Controler doesnt exists"
			: answer_error {code 404}
		}
	}

	:method split_url {} {
		if {[string index ${:url} end] eq "/"} {
			set req_url [string trimright ${:url} /]
		}
		return [file split ${:url}]
	}
	
	:method get_header {args} {
		set what [lindex $args 0]
		# puts "HEADER: [dz::ns_set_to_dict ${:obj_header}]"
		if {$what eq "content_type"} {
			set CT_str [ns_set iget ${:obj_header} "Content-Type"]
			if {[set idx [string first ";" $CT_str]] != -1} {
				set ct [string range $CT_str 0 [expr $idx -1]]
			} else {
				set ct $CT_str
			}
			return $ct
		} elseif {$what eq "content_length" } {
			return [ns_set iget ${:obj_header} "Content-Length"]
		}
	}
	
	:method get_body {} {
		set params ""
		set content_type [: get_header content_type]
		set content_length [: get_header content_length]

		# Define a mapping of content types to handler methods
		set content_handlers {
			"application/json"                 handle_json_body
			"application/x-www-form-urlencoded" handle_form_body
			"multipart/form-data"              handle_form_body
			"text/html"                        handle_text_body
			"text/plain"                       handle_text_body
			"application/xml"                  handle_text_body
		}
		
		if {$content_type eq "" && ${:reqType} in {GET DELETE}} {
			return [: handle_form_body]
		} elseif {[dict exists $content_handlers $content_type]} {
			# puts "EXECUTING : [dict get $content_handlers $content_type]"
			return [: [dict get $content_handlers $content_type]]
		} elseif {$content_length ne 0} {
			# puts "EXECUTING BIN : $content_length"
			return [: handle_binary_body]
		} else {
			oodzLog warning "Empty payload."
			return $params
		}
	}

	:method handle_json_body {} {
		try {
			return [json::json2dict [ns_getcontent -as_file false -binary false]]
		} on error {} {
			oodzLog error "JSON payload is malformed."
			: answer_error [dict create code 400 details "JSON payload is malformed."]
			return 0
		}
	}

	:method handle_form_body {} {
		try {
			set req [::oodz::requestPayload new]
			return $req
		} on error {e} {
			oodzLog error "Error getting form data."
			: answer_error [dict create code 400 details "Form payload is malformed. $e"]
			return 0
		}
	}

	:method handle_text_body {} {
		try {
			return [ns_getcontent -as_file false -binary false]
		} on error {} {
			oodzLog error "Unable to process text content."
			: answer_error [dict create code 400 details "Unable to process text content."]
			return 0
		}
	}

	:method handle_binary_body {} {
		try {
			return [ns_getcontent -as_file true -binary true]
		} on error {} {
			oodzLog error "Unable to process binary content."
			: answer_error [dict create code 400 details "Unable to process binary content."]
			return 0
		}
	}
	
	############################################################################################################
	# Target HTTP
	############################################################################################################

	############################################################################################################
	# Target API
	############################################################################################################
	:method answer_error {args} {
		set json_head [lindex $args 0]
		set content_type [lindex $args 1]
		set status [lindex $args 2]

		set json [new_CkJsonObject]
		CkJsonObject_put_Utf8 $json 1
		CkJsonObject_AddStringAt $json -1 "version" "${:api_version}"
		CkJsonObject_AddStringAt $json -1 "currentTime" [clock format [clock seconds] -format "%y-%m-%d %H:%M:%S"]
		CkJsonObject_AddStringAt $json -1 "method" "${:reqType}"
		CkJsonObject_AddStringAt $json -1 "request" "${:url}"
		if {$status eq ""} {
			CkJsonObject_AddStringAt $json -1 "status" "ERROR"
		} else {
			CkJsonObject_AddStringAt $json -1 "status" "[string toupper $status]"
		}
		dict for {key val} $json_head {
			if {$key eq "code"} {
				CkJsonObject_AddNumberAt $json -1 "$key" $val
				CkJsonObject_AddStringAt $json -1 "errorMessage" [dict getnull ${:error_codes} $val]
			} else {
				CkJsonObject_AddStringAt $json -1 "$key" "$val"
			}
		}
		set numcode [dict get $json_head code]
		CkJsonObject_put_EmitCompact $json 0
		ns_return $numcode ${:obj_answer_content_type} [CkJsonObject_emit $json]
		delete_CkJsonObject $json
		:destroy
	}

	:method answer_good {args} {
		set json_head [lindex $args 0]
		set content_type [lindex $args 1]
		set status [lindex $args 2]
		set redirect_url [lindex $args 3]

		set json [new_CkJsonObject]
		CkJsonObject_put_Utf8 $json 1
		CkJsonObject_AddStringAt $json -1 "version" "${:api_version}"
		CkJsonObject_AddStringAt $json -1 "currentTime" [clock format [clock seconds] -format "%y-%m-%d %H:%M:%S"]
		CkJsonObject_AddStringAt $json -1 "method" "${:reqType}"
		CkJsonObject_AddStringAt $json -1 "request" "${:url}"
		if {$status eq ""} {
			CkJsonObject_AddStringAt $json -1 "status" "SUCCESS"
		} else {
			CkJsonObject_AddStringAt $json -1 "status" "[string toupper $status]"
		}
		dict for {key val} $json_head {
			if {$key eq "code"} {
				CkJsonObject_AddNumberAt $json -1 "$key" $val
			} elseif {$key eq "data"} {
				if {$content_type eq "application/json"} {
					set tmpJsonObj [new_CkJsonObject]
					CkJsonObject_put_Utf8 $tmpJsonObj 1
					CkJsonObject_Load $tmpJsonObj $val
					CkJsonObject_AddObjectCopyAt $json -1 "$key" $tmpJsonObj
					delete_CkJsonObject $tmpJsonObj
				} else {
					CkJsonObject_AddStringAt $json -1 "$key" $val
				}
			} else {
				# Add as a string
				CkJsonObject_AddStringAt $json -1 "$key" "$val"
			}
		}

		set numcode [dict get $json_head code]

		CkJsonObject_put_EmitCompact $json 0
		ns_return $numcode ${:obj_answer_content_type} [CkJsonObject_emit $json]
		delete_CkJsonObject $json
		:destroy
	}
	
	:method answer {args} {
		set response [lindex $args 0]
		#puts  "------------------------------------------"
		#puts $response
		#puts  "------------------------------------------"
		switch [dict getnull $response type] {
			json {set content_type "application/json"}
			xml {set content_type "application/xml"}
			text {set content_type "text/plain"}
			html {set content_type "text/html"}
			binary {set content_type "application/octet-stream"}
			default {set content_type "application/json"}
		}
		set code [dict getnull $response code]
		set data [dict getnull $response data]
		set status [dict getnull $response status]
		set redirect_url [dict getnull $response redirect_url]
		set only_data [dict getnull $response only_data]

		# Check if its an error code
		if {[dict exists ${:error_codes} $code] == 1} {
			: answer_error [dict create code $code details [dict getnull $response details]] $content_type $status
		} elseif {[dict exists ${:redirect_codes} $code] == 1} {
			ns_returnredirect $redirect_url
			:destroy
		} else {
			if {$code == 200 && [dict getnull $response type] eq "binary"} {
				: return_file $data
			} elseif {$code == 200} {
				if {$only_data eq 1} {
					ns_return $code $content_type $data
				} else {
					: answer_good [dict create code $code details [dict getnull $response details] data $data redirect_url $redirect_url] $content_type $status
				}
			}
		}
	}

	:public method return_file {filepath} {
		set filename [file tail $filepath]
		ns_set put [ns_conn outputheaders] Content-Disposition "attachment; filename=\"${filename}\""
		ns_returnfile 200 [ns_guesstype $filepath] $filepath
		:destroy
	}
	
	:method destroy {} {
		puts "Destroying [self]"
		next; # physical destruction
	}
}