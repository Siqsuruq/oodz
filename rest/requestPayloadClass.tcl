namespace eval oodz {
	nx::Class create requestPayload -superclass baseClass {
		:property {content_type "json"}

		:method init {} {
			try {
				if {${:content_type} eq "json"} {
					set requestData [ns_json parse -nullvalue "" -output dict [ns_getcontent -as_file false -binary false]]
					: add $requestData
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
			} on error {errMsg} {
				::oodzLog error "Class=requestPayload method=init error=$errMsg"
				return -code error "$errMsg"
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
	}
}