namespace eval oodz {
	nx::Class create baseObj -superclass baseClass {
		:property {identifier ""}
		:property {obj:required}
		
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
			 	set errMsg "Cant init object TABLE doesnt exist"
				::oodzLog error "Class=baseObj method=init table=${:obj} error=$errMsg"
			 	return -code error $errMsg
			}
		}

		:method read {idType} {
			if {$idType eq "uuid"} {
				return [::db select_obj ${:obj} "uuid_${:obj}='${:identifier}'"]
			} elseif {$idType eq "id"} {
				return [::db select_obj ${:obj} "${:obj}.id='${:identifier}'"]
			}
		}
		
		:public method load_data {key val} {
			if {$key ne "" && $val ne ""} {
				try {
					#set result [lindex [::db select_all ${:obj} * ${:obj}.$key=\'$val\'] 0]
					set result [::db select_obj ${:obj} "${:obj}.$key='$val'"]
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

############################################################## EXTRA ##############################################################
		:public method get_extra {{key ""}} {
			try {
				set data [:get extra]
				set extra [dict getdef $data extra ""]
				if {$key eq ""} {
					return $extra
				}
				return [dict getdef $extra $key ""]
			} on error {errMsg} {
				::oodzLog error "Class=baseObj method=get_extra error=$errMsg"
				return -code error $errMsg
			}
		}

		:public method set_extra {key value} {
			try {
				if {$key eq ""} {
					return -code error "Extra key cannot be empty"
				}
				set extra [:get_extra]
				dict set extra $key $value
				:add [dict create extra $extra]
				return $value
			} on error {errMsg} {
				::oodzLog error "Class=baseObj method=set_extra error=$errMsg"
				return -code error $errMsg
			}
		}

		:public method append_extra {key value} {
			try {
				if {$key eq ""} {
					return -code error "Extra key cannot be empty"
				}
				set value [concat [:get_extra $key] $value]
				:set_extra $key $value
				return $value
			} on error {errMsg} {
				::oodzLog error "Class=baseObj method=append_extra error=$errMsg"
				return -code error $errMsg
			}
		}

		:public method delete_extra {key} {
			try {
				if {$key eq ""} {
					return -code error "Extra key cannot be empty"
				}
				set extra [:get_extra]
				if {![dict exists $extra $key]} {
					return -code ok
				}
				set id [:id get]
				# Delete from database if object already exists
				if {$id ne ""} {
					::db delete_hstore ${:obj} $id $key
				}
				# Also update the in-memory object
				dict unset extra $key
				:add [dict create extra $extra]
				return -code ok
			} on error {errMsg} {
				::oodzLog error "Class=baseObj method=delete_extra error=$errMsg"
				return -code error $errMsg
			}
		}

		:public method save_extra {} {
			try {
				set id [:id get]
				if {$id eq ""} {
					return -code error "Cannot save extra: object has no id"
				}
				set extra [:get_extra]
				if {[dict size $extra] == 0} {
					return -code ok
				}
				::db update_hstore ${:obj} $id $extra
				return -code ok
			} on error {errMsg} {
				::oodzLog error "Class=baseObj method=save_extra error=$errMsg"
				return -code error $errMsg
			}
		}
############################################################## Defaults ##############################################################
		:public method load_default {args} {
			set a [lindex $args 0]
			try {
				if {$a ne ""} {
					set result [::db select_obj ${:obj} "${:obj}.$a IS TRUE"]
				} else {
					set result [::db select_obj ${:obj} "${:obj}.def IS TRUE"]
				}
				if {[llength $result] > 0} {
					:add $result
					:update_identifier
				} else {
					return -code error "No default data found."
				}
			} on error {errMsg} {
				::oodzLog error "Class=baseObj method=load_default table=${:obj} error=$errMsg"
				return -code error $errMsg
			}
		}

		:public method save2db {args} {
			try {
				set obj_data [:prepare_data]
				if {[dict exists $obj_data id] || [dict exists $obj_data uuid_${:obj}]} {
					set res [::db update_all ${:obj} $obj_data]
				} else {
					set res [lindex [::db insert ${:obj} [list $obj_data]] 0]
					: load_data uuid_${:obj} [dict get $res uuid_${:obj}]
				}
				return -code ok $res
			} on error {errMsg} {
				::oodzLog error "Class=baseObj method=save2db table=${:obj} error=$errMsg"
				return -code error $errMsg
			}
		}

		:public method delete {args} {
			try {
				set values [:get]
				set uuidKey uuid_${:obj}
				set uuid [dict getnull $values $uuidKey]
				set id [dict getnull $values id]

				if {![string equal $uuid ""]} {
					set res [::db delete_row ${:obj} $uuid]
					:clear
					return -code ok $res
				} elseif {![string equal $id ""]} {
					set res [::db delete_row ${:obj} $id]
					:clear
					return -code ok $res
				} else {
					return -code error "No id or uuid_${:obj} found"
				}
			} on error {errMsg} {
				::oodzLog error "Class=baseObj method=delete table=${:obj} error=$errMsg"
				return -code error $errMsg
			}
		}

		:method prepare_data {} {
			try {
				set obj_data [:get]
				if {![::oodz::DataType is_dbid [dict getnull $obj_data id]]} {
					set obj_data [dict unset obj_data id]
				}
				if {![::oodz::DataType is_dbid [dict getnull $obj_data uuid_${:obj}]]} {
					set obj_data [dict unset obj_data uuid_${:obj}]
				}
				set obj_data [dict unset obj_data extra]
				set obj_data [dict unset obj_data obj]
				set obj_data [dict unset obj_data identifier]
				set obj_data [dict unset obj_data created_at]
				set obj_data [dict unset obj_data updated_at]
				return $obj_data
			} on error {errMsg} {
				::oodzLog error "Class=baseObj method=save2db error=$errMsg"
				return -code error $errMsg
			}
			
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