namespace eval oodz {
	nx::Class create requestPayload -superclass baseClass {
		:property {request:required}

		:method init {} {
			try {
			foreach {key value} [ns_set array ${:request}] {
				if {$key eq "allTableRows" || $key eq "selectedRows"} {
					:convertJsonToDict $key $value
				} else {
					:add [dict create $key $value]
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

		:public method clear_request_data {args} {
			puts "Clearing request data"
			set result ""
			set code "ok"
			try {
				: remove [list allTableRows selectedRows additionalData message redirectLink request]
			} on error {e} {
				set code "error"
				set result "$e"
			} finally {
				return -code $code $result
			}
		}
	}
}