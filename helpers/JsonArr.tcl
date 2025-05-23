namespace eval ::oodz {
	nx::Class create JsonArr -superclass Json {
	
		:method init {} {
			set :jsonArr [new_CkJsonArray]
			CkJsonArray_put_Utf8 ${:jsonArr} 1
		}

		# method to convert flat Tcl Dict values to JSON
		:public method addList {listval} {
			foreach val $listval {
				if {$val eq "null" || $val eq ""} {
					:addNull
				} elseif {[string is integer -strict $val]} {
					:addInt $val
				} elseif {[string is double -strict $val] || [string is wideinteger $val]} {
					:addNumber $val
				} elseif {[string is boolean -strict $val]} {
					:addBool $val
				} else {
					:addString $val
				}
			}
		}

		# methods for different datatypes values
		:public method addNull {} {
			CkJsonArray_AddNullAt ${:jsonArr} -1
		}
		
		:public method addInt {value} {
			CkJsonArray_AddIntAt ${:jsonArr} -1 "$value"
		}
		
		:public method addNumber {value} {
			CkJsonArray_AddNumberAt ${:jsonArr} -1 "$value"
		}
		
		:public method addBool {value} {
			CkJsonArray_AddBoolAt ${:jsonArr} -1 "$value"
		}
		
		:public method addString {value} {
			CkJsonArray_AddStringAt ${:jsonArr} -1 "$value"
		}
		
		# method to load and add json object from string
		:public method addObject {value} {
			set jObj [new_CkJsonObject]
			CkJsonObject_put_Utf8 $jObj 1
			CkJsonObject_Load $jObj "$value"
			CkJsonArray_AddObjectCopyAt ${:jsonArr} -1 $jObj
			delete_CkJsonObject $jObj
		}

		:public method Load {jsonStr} {
			try {
				CkJsonArray_Load ${:jsonArr} $jsonStr
				return -code ok
			} on error {err} {
				return -code error "Error loading JSON array: $err"
			}
		}

		:public method getSize {} {
			set size [CkJsonArray_get_Size ${:jsonArr}]
			return $size
		}

		:public method getObject {index} {
			try {
				set jObj [CkJsonArray_ObjectAt ${:jsonArr} $index]
				return -code ok $jObj
			} on error {errMsg} {
				return -code error "Error getting JSON object at index $index: $errMsg"
			}
		}

		:public method asJSON {} {
			CkJsonArray_put_EmitCompact ${:jsonArr} 0
			set res [CkJsonArray_emit ${:jsonArr}]
			return $res
		}
		
		:public method destroy {} {
			delete_CkJsonArray ${:jsonArr}
			next
		}
	}
}