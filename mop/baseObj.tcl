namespace eval mop {
	nx::Class create baseObj -superclass baseClass {
		:property -accessor public {identifier ""}
		:property -accessor public obj:required
		
		:method init {args} {
			if {[::db table_exists ${:obj}] eq 1} {
			 	if {${:identifier} ne "" && [::oodz::DataType is_uuid ${:identifier}] == 1} {
			 		:add [: read uuid]
			 	} elseif {${:identifier} ne "" && [string is entier -strict ${:identifier}] == 1} {
			 		:add [: read id]
			 	} else {
                    set a [::db get_columns_names ${:obj}]
                    foreach line $a {
                        set propname [dict get $line column_name]
                        :add [dict create $propname ""]
                    }
                }
			} else {
			 	oodzLog error "Cant init object TABLE doesnt exist"
			 	return -code error "Cant init object TABLE/VIEW doesnt exist"
			}
		}

        :method read {idType} {
		 	if {$idType eq "uuid"} {
		 		return [lindex [::db select_all ${:obj} * uuid_${:obj}=\'${:identifier}\'] 0]
		 	} elseif {$idType eq "id"} {
		 		return [lindex [::db select_all ${:obj} * ${:obj}.id=\'${:identifier}\'] 0]
		 	}
		}
		
		:public method load_data {key val} {
			if {$key ne "" && $val ne ""} {
				try {
					set result [lindex [::db select_all ${:obj} * ${:obj}.$key=\'$val\'] 0]
					if {[llength $result] > 0} {
						:add $result
						:update_identifier
					} else {
						return -code error "No data found for key: $key and value: $val"
					}
				} on error {errMsg} {
					return -code error $errMsg
				}
			} else {
				return -code error "Key and value must not be empty"
			}
		}
		
		:method update_identifier {} {
			set :identifier [dict getnull [:get uuid_${:obj}] identifier]
		}
		
		:public object method create {args} {
			error "Cannot instantiate abstract class [self]"
		}
	}
}