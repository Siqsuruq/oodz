nx::Class create oodz_restansw -superclass apiin {
	:method init {} {
		set :obj_answer_content_type "application/json"
		set :obj_ts [ns_localsqltimestamp]
		set :obj_uuid [ns_uuid]
		# REST must be stateless
		# set :obj_sid [ns_session id]
		set :obj_header [ns_conn headers]
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

}