#
# Scripted Value Constraint. Value checker named "uuid"
#
# # ::nx::Slot method type=uuid {name value} {
	# # if {[regexp {([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})} $value] != 1} {
		# # error "Value '$value' of parameter $name is not UUID"
	# # }
# # }

::nx::ObjectParameterSlot method type=uuid {name value} {
	set pattern {^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$}
	if {![regexp $pattern $value]} {
		error "Value '$value' of parameter $name is not UUID"
	}
	return $value
}


nx::Class create oodz_baseclass -superclass oodz_superclass {
	:property {obj_data ""}
	
	:method init {} {
		if {${:obj_data} ne "" && [dict is_dict ${:obj_data}] == 1} {
		} else {set :obj_data ""}
	}


################################################################
	# Object data manipulation methods
	
	# Public interface to add or modify values in an object, need dicttool package
	# Accepts only one argument, type dict, key value pairs to add or if key exists replace value
	:public method add {args} {
		set a [lindex $args 0]
		if {$a ne "" && [dict is_dict $a] == 1} {
			foreach key [dict keys $a] {
				dict set :obj_data  $key [dict get $a $key]
			}
		}
	}

	# Public interface to remove specific keys from object data, accepts list as of keys as parameter
	:public method remove {args} {
		set to_remove [lindex $args 0]
		foreach key $to_remove {
			dict unset :obj_data $key
		}
	}

	# Public interface to replace specific keys from object data, accepts dict as a parameter. old_key -> new_key
	:public method replace {args} {
		set a [lindex $args 0]
		if {$a ne "" && [dict is_dict $a] == 1} {
			foreach key [dict keys $a] {
				if {[set new_key [dict getnull $a $key]] ne ""} {
					dict set :obj_data $new_key [dict getnull ${:obj_data} $key]
					: remove $key
				}
			}
		}
	}

	# Public interface to erase all data or some specific keys, accept 2 parameters first must be data and second, list of keys to delete. If only one parameter "data" supplied erase all data
	# Probably wrong definition about delete key, must chane to se t empty string
	:public method clear {args} {
		set params [lindex $args 1]
		if {[lindex $args 0] eq "data"} {
			if {$params ne ""} {
				foreach param $params {
					: remove $param
				}
			} else {
				set :obj_data ""
			}
		}
	}

	# Public part to get data from obj_data property
	:public method get {args} {
		set params [lindex $args 1]
		set result_type [lindex $args 2]
		if {$result_type eq ""} { set result_type "D" } elseif {$result_type ne "" && $result_type ne "L"} { set result_type "D" }
		if {[lindex $args 0] eq "srv"} {return ${:srv}}
		if {[lindex $args 0] eq "path"} {return ${:path}}
		if {[lindex $args 0] eq "srvaddress"} {return ${:srvaddress}}
		if {[lindex $args 0] eq "id"} {
			set :id [dict getnull ${:obj_data} id]
			return ${:id}
		}
		if {[lindex $args 0] eq "name"} {
			return [dict getnull ${:obj_data} name]
		}
		if {[lindex $args 0] eq "data"} {
			set res ""
			if {$params ne ""} {
				foreach param $params {
					dict append res $param [dict getnull ${:obj_data} $param]
				}
			} else {set res ${:obj_data}}
			: format_result $res $result_type
		}
	}
	
	# Return 1 if object data is empty, 0 otherwise
	:public method is_empty {args} {
		if {${:obj_data} eq ""} {
			return 1
		} else {
			return 0
		}
	}
	# Return 1 if object data is not empty, 0 otherwise
	:public method is_not_empty {args} {
		if {${:obj_data} eq ""} {
			return 0
		} else {
			return 1
		}
	}
	
	:method format_result {result {result_type "D"}} {
		if {$result_type eq "D"} {
			return $result
		} else {
			return [dict values $result]
		}
	}
	
	:method unknown {called_method args} {
		oodzLog warning "Unknown method '$called_method' called"
	}
}