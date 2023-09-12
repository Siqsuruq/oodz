namespace eval oodz {
	nx::Class create Session {
		:property {cookie_name "sessionId"}
		:property {timeout 2}
		:property {session_expire 600} 
		:property {cookie_expire false}
		:property {expires ""}
		:property {touch "1"}
		:property {persist "1"}
		:property {persist_type "file"}
		:property {cookie_secure 1}
		:property {cookie_scriptable 1}
		:property {storageObj:object}

		# Constructor
		:method init {} {
			set :dom_sess [ns_info server]_sessions_cl
			ns_cache_create -timeout ${:timeout} -expires ${:session_expire} ${:dom_sess} 10MB
			switch ${:persist_type} {
				"file" {
					set :storageObj [::oodz::SessionFile new]
				}
				"db" {
					set :storageObj [::oodz::SessionDB new]
				}
				default {
					error "Unsupported storage type: ${:persist_type}"
				}
			}
		}

		:public method id {} {
			set sessionId [ns_getcookie ${:cookie_name} 0]
			if {$sessionId == 0} {
				set sessionId [ns_sha1 [uuid::uuid generate][ns_rand 100000]]
				# If cookie expire false it will be session cookie
				if { [::oodz::DataType is_bool ${:cookie_expire}] == 0} {
					ns_setcookie -discard 1 -secure ${:cookie_secure} -scriptable ${:cookie_scriptable} ${:cookie_name} $sessionId
				} else {
					ns_setcookie -secure ${:cookie_secure} -scriptable ${:cookie_scriptable} -expires ${:cookie_expire} ${:cookie_name} $sessionId
				}
			}
			return $sessionId
		}

		# Data lifecycle related
		:public method add {data} {
			set sessionId [:id]
			${:storageObj} save $sessionId $data
		}

		:public method eliminate {args} {
			set keys [lindex $args 0]
			set sessionId [:id]
			${:storageObj} eliminate $sessionId $keys
		}

		:public method get {args} {
			set keys [lindex $args 0]
			set sessionId [:id]
			${:storageObj} load $sessionId $keys
		}

		# Session lifecycle related
		:public method purge {} {
			set sessionId [:id]
			ns_deletecookie -secure ${:cookie_secure} ${:cookie_name}
			${:storageObj} purge $sessionId
		}
		
		:public method exists {} {
			set sessionId [ns_getcookie ${:cookie_name} 0]
			if {$sessionId == 0} {
				return 0
			} else {
				if {}
				if {[set data [${:storageObj} exists $sessionId]] eq ""} {
					return 0
				} else {
					return 1
				}
			}
		}
	}
}
