namespace eval oodz {
	nx::Class create baseClass -superclass superClass {
		:property {obj_data ""}
		:property {obj_dataType ""}
		
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
				set :obj_data [dict merge ${:obj_data} $a]
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
						: remove [list $param]
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
			if {[lindex $args 0] eq "namespace"} {return [namespace current]}
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
		
		# Basic validation methods
		:public method validate_keys {args} {
			set keys_to_check [lindex $args 0]
			foreach key $keys_to_check {
				if {![dict exists ${:obj_data} $key]} {
					return 0
				}
			}
			return 1
		}

		:public method validate_values_not_empty {args} {
			set keys_to_check [lindex $args 0]
			foreach key $keys_to_check {
				if {![dict exists ${:obj_data} $key] || [dict get ${:obj_data} $key] eq ""} {
					return 0
				}
			}
			return 1
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
		
		# :public method asJSON {} {
			# if {[: is_not_empty]} {
				# ::oodz::JsonObj create json_obj
				# json_obj dict2Json ${:obj_data}
				# set jstring [json_obj JsonStr]
				# json_obj destroy
				# return $jstring
			# }
		# }

		:public method asJSON {} {
			if {[: is_not_empty]} {
				return [tcl2json ${:obj_data}]
			}
		}

		:public method asNSSET {key} {
			if {[: is_not_empty]} {
				return [ns_set create $key ${:obj_data}]
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
}