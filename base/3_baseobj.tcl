namespace eval oodz {
	nx::Class create baseObj -superclass baseClass {
		:property {identifier ""}
		:property obj:required
		:property {db:object,required}
		
		:method init {} {
			next
			if {[${:db} table_exists ${:obj}] eq 1} {
				if {${:identifier} ne "" && [::oodz::DataType is_uuid ${:identifier}] == 1} {
					set :obj_data [: read uuid]
				} elseif {${:identifier} ne "" && [string is entier -strict ${:identifier}] == 1} {
					set :obj_data [: read id]
				}
			} else {
				oodzLog error "Cant init object TABLE doesnt exist"
				return -code error "Cant init object TABLE/VIEW doesnt exist"
			}
		}

	################################################################
	# Basic CRUD operations
	################################################################
						  
										
	  

		:method read {args} {
			set idType [lindex $args 0]
			if {$idType eq "uuid"} {
				return [lindex [${:db} select_all ${:obj} * uuid_${:obj}=\'${:identifier}\'] 0]
			} elseif {$idType eq "id"} {
				return [lindex [${:db} select_all ${:obj} * ${:obj}.id=\'${:identifier}\'] 0]
			}
		}
		
		:public method delete {args} {
			if {![: is_empty]} {
				${:db} delete_rows ${:obj} [: get uuid]
			}
		}

	################################################################

		# Public part to get data
		:public method get {args} {
			set params [lindex $args 1]
			set result_type [lindex $args 2]
			if {$result_type eq ""} { set result_type "D" } elseif {$result_type ne "" && $result_type ne "L"} { set result_type "D" }
			if {[lindex $args 0] eq "identifier"} {return ${:identifier}}
			# Atention in the case of views this will return empty value ass uuid
			if {[lindex $args 0] eq "uuid"} {
				set :uuid [dict getnull ${:obj_data} uuid_${:obj}]
				return ${:uuid}
			}
			if {[lindex $args 0] eq "data_prefix"} {
				set prefix $params
				if {$prefix eq ""} {set prefix ${:obj}}
				set res [dict create]
				foreach {k v} ${:obj_data} {
					oodzLog notice "$k  + $v " 
					dict append res ${prefix}_$k $v
				}
				: format_result $res
			}
			next
		}
		
		:method update_identifier {} {
			if {[:is_empty] != 1} {
				set :identifier [:get uuid]
			}
		}
		
		:public method load_data {args} {
			set a [lindex $args 0]
			if {$a ne "" && [dict is_dict $a] == 1} {
				foreach key [dict keys $a] {
					set :obj_data [lindex [${:db} select_all ${:obj} * ${:obj}.$key=\'[dict get $a $key]\'] 0]
				}
			}
			:update_identifier
		}
		
		# Should always return id and uuid
		:public method save2db {args} {
			if {[catch { set res [${:db} insert_all ${:obj} ${:obj_data} "" [list uuid_${:obj}]] } err]} {
				return -code error $err
			} else {
				: load_data [dict create uuid_${:obj} [lindex $res 0]]
				return -code ok [lindex $res 0]
			}
		}
		
		:public method load_default {args} {
			set a [lindex $args 0]
			if {$a ne ""} {
				set :obj_data [lindex [${:db} select_all ${:obj} * "${:obj}.$a IS TRUE"] 0]
			} else {
				set :obj_data [lindex [${:db} select_all ${:obj} * "${:obj}.def IS TRUE"] 0]
			}
			:update_identifier
		}
		
		:method format_result {result {result_type "D"}} {
			if {$result_type eq "D"} {
				return $result
			} else {
				return [dict values $result]
			}
		}
	}
}