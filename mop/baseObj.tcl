namespace eval mop {
	nx::Class create baseObj -superclass baseClass {
        :property -accessor public {identifier ""}
        :property -accessor public {obj:required}
        # :property -accessor public {db:required ${::db}}

		:method init {args} {
            next
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

        :method read {args} {
		 	set idType [lindex $args 0]
		 	if {$idType eq "uuid"} {
		 		return [lindex [::db select_all ${:obj} * uuid_${:obj}=\'${:identifier}\'] 0]
		 	} elseif {$idType eq "id"} {
		 		return [lindex [::db select_all ${:obj} * ${:obj}.id=\'${:identifier}\'] 0]
		 	}
		}
	}
}