nx::Class create apiin -superclass oodz_superclass {
	:property reqType:required
	:property url:required
	:property auth:required
	:property ssl:required
	:property api_version:required
	
	:method init {} {
		set :obj_answer_content_type "application/json"
		set :obj_ts [ns_localsqltimestamp]
		set :obj_uuid [ns_uuid]
		# REST must be stateless
		# set :obj_sid [ns_session id]
		set :obj_header [ns_conn headers]
		oodzLog notice "************ API CALL ******************"
		oodzLog notice "METHOD: ${:reqType}"
		oodzLog notice "URL: ${:url}"
		oodzLog notice "****************************************"
	}
	
	:public method inf {args} {
		switch [lindex $args 0] {
			obj_ts {
				return ${:obj_ts}
			}
			obj_domain {
				return ${:obj_domain}
			}
			obj_uuid {
				return ${:obj_uuid}
			}
			# obj_sid {
				# return ${:obj_sid}
			# }
			default {
				return [dict create obj_domain ${:srv} obj_uuid ${:obj_uuid} obj_ts ${:obj_ts}]
			}
		}
	}
	
	:public method answer_request {args} {
		if {[[self] cget -ssl] ne "nsssl"} {
			: answer_error {code 405 detail "HTTP Requests are Not Allowed, please use HTTPS"}	
		} else {
			set surl [[self] split_url]
			set resource [lindex $surl 3]
			# must change this part to be more general
			read_config

			#Check if resource folder exists and if it has API proc
			if {[file isdirectory [file join ${:srvpath} [set ${:srv}::mod_dir] $resource]] == 1 && [info proc ::${resource}::api] ne ""} {
				oodzLog notice "It exists"
				set params [: get_body]
				set values [lrange $surl 4 end]
				# # Execute call and get result list.
				# set result [::${resource}::api $method $values $params $url]
				# ::api::response $result
				set content "REQUEST TYPE: ${:reqType}<br/ >URL: ${:url}<br/ >REQUESTED: [: get_header content_type]<br /><hr>$params <hr> $values"
				ns_return 200 text/html $content
			} else {
				: answer_error {code 404}
			}
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
	
	# Accepted: none, json, form-data, x-www-form-urlencoded, raw, binary
	# this method will convert body data to Tcl dict
	:method get_body {args} {
		set params ""
		set content_type [: get_header content_type]
		set content_length [: get_header content_length]
		# API can accept GET requests with non empty body, only multipart/form-data and application/x-www-form-urlencoded
		if {${:reqType} in {GET DELETE}} {
			set params [dz::ns_set_to_dict [ns_getform]]
		} elseif {${:reqType} in {POST PUT}} {
			if {$content_type eq "application/json"} {
				set params [json::json2dict [ns_getcontent -as_file false -binary false]]
			} elseif {$content_type eq "application/x-www-form-urlencoded" || $content_type eq "multipart/form-data"} {
				set params [dz::ns_set_to_dict [ns_getform]]
			} elseif {$content_type eq "text/html" || $content_type eq "text/plain"} {
				set params [ns_getcontent -as_file false -binary false]
			} elseif {$content_type eq "application/xml"} {
				set params [ns_getcontent -as_file false -binary false]
			} elseif {$content_length ne 0} {
				set params [ns_getcontent -as_file true -binary true]
			} else {
				puts "NO BODY CONTENT"
			}
		}
		return $params
	}
	
	
	:method answer_error {args} {
		set codes [dict create 400 "Bad request" 401 "Unauthorized" 403 "Forbidden" 404 "Resource not found" 405 "Method not allowed" 413 "Request Entity Too Large" 418 "I'm a teapot" 500 "Internal server error"]
		
		set json_head [lindex $args 0]
		set json [new_CkJsonObject]
		CkJsonObject_put_Utf8 $json 1
		
		CkJsonObject_AddStringAt $json -1 "version" "${:api_version}"
		CkJsonObject_AddStringAt $json -1 "currentTime" "${:obj_ts}"
		CkJsonObject_AddStringAt $json -1 "status" "ERROR"
		dict for {key val} $json_head {
			if {$key eq "code"} {
				CkJsonObject_AddNumberAt $json -1 "$key" $val
				CkJsonObject_AddStringAt $json -1 "text" [dict getnull $codes $val]
			} else {
				CkJsonObject_AddStringAt $json -1 "$key" "$val"
			}
		}
		set numcode [dict get $json_head code]
		CkJsonObject_AddStringAt $json -1 "method" "${:reqType}"
		CkJsonObject_AddStringAt $json -1 "request" "${:url}"
		CkJsonObject_put_EmitCompact $json 0
		ns_return $numcode ${:obj_answer_content_type} [CkJsonObject_emit $json]
		delete_CkJsonObject $json
	}
	
	:method answer {} {
	
	}
}