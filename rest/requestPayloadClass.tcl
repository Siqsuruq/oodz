namespace eval oodz {
	nx::Class create requestPayload -superclass baseClass {
		:property {content_type "json"}

		:method init {} {
			try {
				if {${:content_type} eq "json"} {
					set requestData [ns_json parse -output dict [ns_getcontent -as_file false -binary false]]
					set a [:replace_ns_json_null $requestData]
					: add $a
				} else {
					set requestData [ns_set array [ns_getform]]
					foreach {key value} $requestData {
						if {$key eq "allTableRows" || $key eq "selectedRows"} {
							:convertJsonToDict $key $value
						} else {
							:add [dict create $key $value]
						}
					}
				}
			} on error {e} {
				return -code error "$e"
			}
		}

		:method convertJsonToDict {key json} {
			try {
				set tmpdict [json::json2dict $json]
				:add [dict create $key $tmpdict]
				return -code ok
			} on error {e} {
				return -code error "Error in json2dict"
			}
		}

		:public method get_selected {tableName} {
			if {$tableName eq ""} {
				return -code error "Table name is required"
			}
			try {
				set selectedRows [dict getnull [: selectedRows get] $tableName]
				return $selectedRows
			} on error {e} {
				return -code error "$e"
			}
		}

		:public method get_allrows {tableName} {
			if {$tableName eq ""} {
				return -code error "Table name is required"
			}
			try {
				set allRows [dict getnull [: allTableRows get] $tableName]
				return $allRows
			} on error {e} {
				return -code error "$e"
			}
		}

		:public method clear_request_data {args} {
			set result ""
			set code "ok"
			try {
				: remove [list allTableRows selectedRows additionalData message redirectLink]
			} on error {e} {
				set code "error"
				set result "$e"
			} finally {
				return -code $code $result
			}
		}

		:method replace_ns_json_null {x} {
			set marker "__NS_JSON_NULL__"

			# 1) exact marker => empty string
			if {$x eq $marker} {
				return ""
			}

			# 2) Try dict (only if Tcl accepts it as a dict)
			if {![catch {dict size $x}]} {
				set out {}
				dict for {k v} $x {
					dict set out $k [: replace_ns_json_null $v]
				}
				return $out
			}

			# 3) Try list (only if Tcl accepts it as a proper list)
			# IMPORTANT: Don't treat ordinary strings as lists.
			# We only recurse as a list if:
			#   - it parses as a list, AND
			#   - it has more than 1 element OR it contains the marker somewhere
			if {![catch {llength $x} n]} {
				if {$n > 1 || ($n == 1 && [string first $marker $x] >= 0)} {
					set out {}
					foreach item $x {
						lappend out [: replace_ns_json_null $item]
					}
					return $out
				}
			}

			# 4) scalar / ordinary string
			return $x
		}
	}
}