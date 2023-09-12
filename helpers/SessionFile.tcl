namespace eval oodz {
	nx::Class create SessionFile  {
		:public method save {sessionId {sessionData ""}} {
			set session_data [:load $sessionId]
			if {$sessionData ne "" && [dict is_dict $sessionData] == 1} {
				set fp [: session_file_write $sessionId]
				puts $fp [dict merge $session_data $sessionData]
				close $fp
			}
		}
		
		:public method eliminate {sessionId {keys ""}} {
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
		
		# Load data, if data list is not empty returns only those keys
		:public method load {sessionId {keys ""}} {
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
		
		:public method purge {sessionId} {
			set filename [file join / tmp session_${sessionId}]
			file delete -force $filename
		}

		:public method exists {sessionId} {
			return [: load $sessionId]
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
}