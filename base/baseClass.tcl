namespace eval oodz {
	nx::Class create baseClass {
		:method init {args} {
		}
	################################################################
		# Object data manipulation methods
		:public method add {args} {
			set a [lindex $args 0]
			if {$a ne "" && [dict is_dict $a] == 1} {
				dict for {key value} $a {
					if {[: prop_exists ${key}]} {
						: ${key} set ${value}
					} else {
						:object property -accessor public [list ${key} ${value}]
					}
				}
			} else {
				return -code error "Invalid argument: expected a dictionary"
			}
		}

		:public method prop_exists {key} {
			try {
				set result [: ${key} exists]
			} trap {} {} {
				set result 0
			} finally {
				return $result
			}
		}

		:public method get {{what ""} {result_type D}} {
			# Initialize result as a list or dictionary based on the result_type
			if {$result_type eq "L"} {
				set result [list]
			} else {
				set result [dict create]
			}
			# If no properties are specified, get all variable names
			if {[llength $what] == 0} {
				set what [: info vars]
			}
			# Iterate over the properties and gather their values 
			foreach prop $what {
				if {$result_type eq "L"} {
					if {[:prop_isobj [: cget -${prop}]] == 1} {
						set a [[: cget -${prop}] get]
						lappend result $a
					} else {
						lappend result [: cget -${prop}]
					}
				} else {
					if {[:prop_isobj [: cget -${prop}]] == 1} {
						set a [[: cget -${prop}] get]
						dict set result $prop $a
					} else {
						dict set result $prop [: cget -${prop}]
					}
				}
			}
			return $result
		}

		:method prop_isobj {varName} {
			# Check if the variable is an object by attempting to get its class info
			if { [catch {${varName} info class}] } {
				return 0
			} else {
				return 1
			}
		}

		# Public interface to remove specific keys from object data, accepts list as of keys as parameter
		:public method remove {args} {
			set to_remove [lindex $args 0]
			foreach key $to_remove {
				: ${key} unset
			}
		}

		# Public interface to replace specific keys from object data, accepts dict as a parameter. old_key -> new_key. Values will stay the same.
		:public method replace {args} {
			set a [lindex $args 0]
			if {$a ne "" && [dict is_dict $a] == 1} {
				dict for {old_key new_key} $a {
					if {$old_key ne $new_key} {
						:add [dict create $new_key [: $old_key get]]
						:remove $old_key
					}
				}
			}
		}

		# Public interface to erase all data or some specific keys, make them empty string. If args are not provided will erase all data.
		:public method clear {args} {
			try {
				if {[llength $args] == 0} {
					set objprops [: info vars]
					foreach prop $objprops {
						if {[:prop_isobj [: cget -${prop}]] == 1} {
							[: cget -${prop}] clear
						} else {
							: configure -${prop} ""
						}
					}
				} else {
					foreach param $args {
						if {[:prop_isobj [: cget -${prop}]] == 1} {
							[: cget -${prop}] clear
						} else {
							: configure -${prop} ""
						}
					}
				}
			} on error {errMsg} {
				return -code error $errMsg
			}
		}

		# Return 1 if object has no properties or all properties are empty, 0 otherwise
		:public method is_empty {} {
			set objprops [: info vars]
			if {[llength $objprops] == 0} {
				return 1
			} else {
				foreach prop $objprops {
					if {[: cget -${prop}] ne ""} {
						return 0
					}
				}
				return 1
			}
		}

		# Return 1 if object has properties and at least one of them is not empty, 0 otherwise
		:public method is_not_empty {} {
			set objprops [: info vars]
			if {[llength $objprops] == 0} {
				return 0
			} else {
				foreach prop $objprops {
					if {[: cget ${prop}] ne ""} {
						return 1
					}
				}
				return 0
			}
		}

		:public method asJSON {} {
			return [tcl2json [: get]]
		}
	}
}