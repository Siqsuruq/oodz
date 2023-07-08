namespace eval oodz {
	nx::Class create api -superclass baseClass {
		:property name:required
		:property {reqType "GET POST DELETE PUT"}
		
		:method init {} {
		}
		
		:public method dispatcher {req_method values params url} {
			if {[llength $values] == 0} {
				set dispatcher "${req_method}_${:name}"
			} else {
				set dispatcher [lindex $values 0]
				set values [lrange $values 1 end]
			}
			if {[lsearch -nocase ${:reqType} ${req_method}] != -1} {
				try {
					set result [::${:name}::${dispatcher} ${values} ${params}]
				} on error {errmsg} {
					oodzLog error "$errmsg"
					set result [dict create code 400 detail "Something wrong: $errmsg"]
				} finally {
					return $result
				}
			} else {
				return [dict create code 404 method ${req_method} request ${url}]
			}	
		}
	}
}