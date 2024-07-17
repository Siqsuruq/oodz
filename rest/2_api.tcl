namespace eval oodz {
	nx::Class create api -superclass baseClass {
		:property name:required
		:property {reqType "GET POST DELETE PUT"}
		:property {req_proc_mapping ""}
		
		:method init {} {
			set :req_proc_mapping [dict create]
			foreach req_type ${:reqType} {
				dict set :req_proc_mapping $req_type *
			}
		}
		
		:public method dispatcher {req_method values params url} {
			if {[llength $values] == 0} {
				set dispatcher "${req_method}_${:name}"
			} else {
				set dispatcher [lindex $values 0]
				set values [lrange $values 1 end]
			}
			# This checks if the request method is allowed
			if {[lsearch -nocase ${:reqType} ${req_method}] != -1} {
				# This checks if the request method is mapped to a procedure
				if {[:check_req_proc_mapping ${req_method} ${dispatcher}] != ""} {
					try {
						set result [::${:name}::${dispatcher} ${values} ${params}]
					} on error {errmsg} {
						oodzLog error "$errmsg"
						set result [dict create code 400 detail "Something wrong: $errmsg"]
					} finally {
						return $result
					}
				} else {
					oodzLog notice "Request to not allowed proc: ${req_method}:${url}"
					return [dict create code 400 method ${req_method} request ${url}]
				}
			} else {
				oodzLog notice "Request using not allowed method: ${req_method}:${url}"
				return [dict create code 405 method ${req_method} request ${url}]
			}	
		}

		:public method add_mapping {req_type values} {
			if {[dict exists ${:req_proc_mapping} $req_type] == 0} {
				dict set :req_proc_mapping $req_type *
			}
			if {[llength $values] > 0} {
				foreach value $values {
					set mapping [dict get ${:req_proc_mapping} $req_type]
					if {[lsearch -nocase $mapping $value] == -1} {
						lappend mapping $value
					}
					dict set :req_proc_mapping $req_type $mapping
				}
				:remove_global_mapping $req_type
			}
		}

		:public method remove_mapping {req_type values} {
			if {[dict exists ${:req_proc_mapping} $req_type] == 0} {
				dict set :req_proc_mapping $req_type *
			}
			if {[llength $values] > 0} {
				foreach value $values {
					set mapping [dict get ${:req_proc_mapping} $req_type]
					if {[set idx [lsearch -nocase $mapping $value]] != -1} {
						set new_mapping [lreplace $mapping $idx $idx]
						if {[llength $new_mapping] > 0} {
							dict set :req_proc_mapping $req_type $new_mapping
						} else {
							:delete_mapping $req_type
						}
					}
				}
			}
		}

		:public method remove_global_mapping {req_type} {
			set mapping [dict get ${:req_proc_mapping} $req_type]
			if {[set idx [lsearch -nocase $mapping "*"]] != -1} {
				set new_mapping [lreplace $mapping $idx $idx]
				if {[llength $new_mapping] > 0} {
					dict set :req_proc_mapping $req_type $new_mapping
				} else {
					:delete_mapping $req_type
				}
			}
		}

		:public method delete_mapping {req_type} {
			dict unset :req_proc_mapping $req_type
		}

		:public method get_mapping {args} {
			if {$args eq ""} {
				return ${:req_proc_mapping}
			} else {
				set mapping [dict getnull ${:req_proc_mapping} $args]
				return $mapping
			}
		}

		:method check_req_proc_mapping {req_method dispatcher} {
			set mapping [dict get ${:req_proc_mapping} ${req_method}]
			if {$mapping eq "*"} {
				return $dispatcher
			} else {
				if {[lsearch -nocase $mapping $dispatcher] != -1} {
					return $dispatcher
				} else {
					return ""
				}
			}
		}
	}
}