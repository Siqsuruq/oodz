# Generic object DataType
namespace eval oodz {
	nx::Object create DataType {
		:public object method is_bool {value} {
			set bool_values {1 yes true on enable 0 no false off disable}
			if {$value eq ""} {
				return 0
			} elseif {[string is boolean $value]} {
				return [expr {$value ? 1 : 0}]
			} elseif {[string is integer -strict $value]} {
				return [expr {$value ? 1 : 0}]
			} elseif {[lsearch -exact $bool_values [string tolower $value]] >= 0} {
				return 1
			} else {
				return 0
			}
		}
		:public object method is_uuid {value} {
			set pattern {^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$}
			return [regexp $pattern $value]
		}
		:public object method is_dict {value} {
			return [dict is_dict $value]
		}
	}
}

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
