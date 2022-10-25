nx::Class create oodz_baseclass -superclass oodz_superclass {
	:property {data ""}
	
	:method init {} {
		if {${:data} ne "" && [dict is_dict ${:data}] == 1} {
			set :obj_data ${:data}
		} else {
			set :obj_data ""
		}
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
	
	:method format_result {result {result_type "D"}} {
		if {$result_type eq "D"} {
			return $result
		} else {
			return [dict values $result]
		}
	}
}