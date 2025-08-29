namespace eval ::oodz {
	nx::Class create Json {
		:public method is_json_array {json_str} {
			try {
				# Trim whitespace and check if it starts with [ and ends with ]
				set trimmed [string trim $json_str]
				return [expr {[string index $trimmed 0] eq "\[" && [string index $trimmed end] eq "\]"}]
			} on error {errMsg} {
				return -code error "Error checking JSON array: $errMsg"
			}
		}

		:public method is_json_object {json_str} {
			try {
				# Trim whitespace and check if it starts with { and ends with }
				set trimmed [string trim $json_str]
				return [expr {[string index $trimmed 0] eq "\{" && [string index $trimmed end] eq "\}"}]
			} on error {errMsg} {
				return -code error "Error checking JSON object: $errMsg"
			}
		}

		:public method get_json_type {json_str} {
			try {
				# Determine if the string is a JSON array or object
				if {[:is_json_array $json_str]} {
					return "array"
				} elseif {[:is_json_object $json_str]} {
					return "object"
				} else {
					return "unknown"
				}
			} on error {errMsg} {
				return -code error "Error determining JSON type: $errMsg"
			}
		}
	}
}