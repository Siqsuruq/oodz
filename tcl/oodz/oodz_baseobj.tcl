nx::Class create oodz_baseobj -superclass oodz_superclass {
	:property {identifier ""}
	:property obj:required
	:property obj_data
	
	:method init {} {
		set :obj_data ""
		if {[db table_exists ${:obj}] eq 1} {
			if {${:identifier} ne "" && [is_uuid ${:identifier}] == 1} {
				set :obj_data [: read uuid]
			} elseif {${:identifier} ne "" && [string is entier -strict ${:identifier}] == 1} {
				set :obj_data [: read id]
			}
		} else {
			oodzLog write "Cant init object TABLE doesnt exist"
		}

	}

################################################################
# Basic CRUD operations
################################################################

	:method create {} {
	
	}
	:method read {args} {
		set idType [lindex $args 0]
		if {$idType eq "uuid"} {
			return [dict getnull [select_all ${:obj} * uuid_${:obj}=\'${:identifier}\'] 0]
		} elseif {$idType eq "id"} {
			return [dict getnull [select_all ${:obj} * ${:obj}.id=\'${:identifier}\'] 0]
		}
	}
	:method update {} {
	
	}
	:method delete {} {
		delete_row ${:obj}
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

	# Public part to get data
	:public method get {args} {
		set params [lindex $args 1]
		set result_type [lindex $args 2]
		if {$result_type eq ""} { set result_type "D" } elseif {$result_type ne "" && $result_type ne "L"} { set result_type "D" }
		
		switch [lindex $args 0] {
			srv {
				return ${:srv}
			}
			identifier {
				return ${:identifier}
			}
			uuid {
				set :uuid [dict getnull ${:obj_data} uuid_${:obj}]
				return ${:uuid}
			}
			id {
				set :id [dict getnull ${:obj_data} id]
				return ${:id}
			}
			name {
				return [dict getnull ${:obj_data} name]
			}
			data {
				set res ""
				if {$params ne ""} {
					foreach param $params {
						dict append res $param [dict getnull ${:obj_data} $param]
					}
				} else {set res ${:obj_data}}
				: format_result $res $result_type
			}
			
			data_prefix {
				set prefix $params
				if {$prefix eq ""} {set prefix ${:obj}}
				set res [dict create]
				foreach {k v} ${:obj_data} {
					dict append res ${prefix}_$k $v
				}
				: format_result $res
			}
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