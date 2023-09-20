namespace eval ::oodz {
	nx::Class create SessionClass -superclasses ::nx::Class
	
	SessionClass create ISession {
		:property {cookie_name "sessionId"}
		:property {cookie_expire false}
		:property {cookie_secure 1}
		:property {cookie_scriptable 1}
		
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
		
		:method unknown {called_method args} {
			set msg "Unknown method '$called_method' in [[self] info name] called"
			oodzLog warning $msg
			return $msg
		}
	}
		
	SessionClass create SessionFile -superclasses ISession {
		:public method add {{sessionData ""}} {
			set sessionId [:id]
			set current_session_data [:get]
			if {$sessionData ne "" && [dict is_dict $sessionData] == 1} {
				set fp [:session_file_write $sessionId]
				puts $fp [dict merge $current_session_data $sessionData]
				close $fp
			}
		}
		
		:public method get {{keys ""}} {
			set sessionId [:id]
			set result ""
			set fp [: session_file_read $sessionId]
			set session_data [read $fp]
			close $fp
			if {$session_data ne ""} {
				if {$keys ne ""} {
					foreach key $keys {
						if {[set val [dict getnull $session_data $key]] ne ""} {
							lappend result $val
						}
					}
				} else {
					set result $session_data
				}
			}
			return $result
		}
		
		:public method remove {{keys ""}} {
			set sessionId [:id]
			set result ""
			set fp [: session_file_read $sessionId]
			set session_data [read $fp]
			close $fp
			if {$session_data ne ""} {
				if {$keys ne ""} {
					foreach key $keys {
						dict unset session_data $key
					}
					set fp [: session_file_write $sessionId]
					puts $fp $session_data
					close $fp
				}
			}
			return $result
		}
		
		:public method purge {} {
			set sessionId [:id]
			ns_deletecookie -secure ${:cookie_secure} ${:cookie_name}
			set filename [file join / tmp session_${sessionId}]
			file delete -force $filename
		}

		:public method exists {} {
			set sessionId [:id]
			if {$sessionId == 0} {
				return 0
			} else {
				if {[:get] eq ""} {
					return 0
				} else {
					return 1
				}
			}
		}
		
		:method session_file_read {sessionId} {
			set filename [file join / tmp session_${sessionId}]
			if {[file exists $filename] == 1} {
				return [open $filename r]
			}  else {
				return [open $filename w+]
			}
		}
		
		:method session_file_write {sessionId} {
			set filename [file join / tmp session_${sessionId}]
			return [open $filename w+]
		}
	}	
		
		
		
		
		
		SessionClass create dbs -superclasses ISession
	
	nx::Class create SessionFactory {
		:public method createSession {-persist_type:class,type=SessionClass} {
			return [$persist_type create ::oodzSession]
		}
		:create ::sessionFactory
	}
}