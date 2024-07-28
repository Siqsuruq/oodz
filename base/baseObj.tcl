namespace eval oodz {
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
		
		:public method load_default {args} {
			set a [lindex $args 0]
			try {
				if {$a ne ""} {
					set result [lindex [::db select_all ${:obj} * "${:obj}.$a IS TRUE"] 0]
				} else {
					set result [lindex [::db select_all ${:obj} * "${:obj}.def IS TRUE"] 0]
				}
				if {[llength $result] > 0} {
					:add $result
					:update_identifier
				} else {
					return -code error "No default data found."
				}
			} on error {errMsg} {
				return -code error $errMsg
			}
		}

		:public method save2db {args} {
			try {
				set obj_data [:prepare_data]
				set res [::db insert_all ${:obj} $obj_data "" [list uuid_${:obj} id]]
				: load_data uuid_${:obj} [lindex $res 0]
				return -code ok $res
			} on error {errMsg} {
				return -code error $errMsg
			}
		}

		:method prepare_data {} {
			set obj_data [:get]
			set obj_data [dict unset obj_data id]
			set obj_data [dict unset obj_data uuid_${:obj}]
			set obj_data [dict unset obj_data extra]
			set obj_data [dict unset obj_data obj]
			set obj_data [dict unset obj_data identifier]
			set obj_data [dict unset obj_data created_at]
			set obj_data [dict unset obj_data updated_at]
			return $obj_data
		}

		:method update_identifier {} {
			set idstr [string cat uuid_ [:get obj L]]
			set :identifier [:get $idstr L]
		}
		
		:public object method create {args} {
			error "Cannot instantiate abstract class [self]"
		}
	}
}