namespace eval oodz {
	nx::Class create SessionCache  {
	
		:public method delete {sessionId} {
			set filename [file join / tmp $sessionId]
			file delete -force $filename
		}
		
		:public method save {sessionId {sessionData ""}} {
			set fp [: session_file $sessionId]
			puts $fp $sessionData
			close $fp
		}
		
		:public method touch {} {
			
		}
		
		:method session_file {sessionId} {
			ns_cache_create -timeout ${:timeout} -expires ${:session_expire} ${:dom_sess} 10MB
		}
	}
}