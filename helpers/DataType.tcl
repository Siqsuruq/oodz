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
		
		:public object method is_number {value} {
			if {[string is integer -strict $value] || [string is double -strict $value] || [string is wideinteger $value]} {
				return 1
			} else { return 0 }
		}
		
		:public object method guess_type {value} {
			if {[: is_number]} { return num } else { return str }
		}

		:public object method is_email {value} {
            set pattern {^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$}
            return [regexp $pattern $value]
        }
	}
}
