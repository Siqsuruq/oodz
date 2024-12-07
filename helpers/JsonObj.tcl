namespace eval ::oodz {
	nx::Class create JsonObj -superclass Json {
	
		:method init {} {
			set :json [new_CkJsonObject]
			CkJsonObject_put_Utf8 ${:json} 1
		}

		# method to convert flat Tcl Dict values to JSON
		:public method addDict {dictval} {
			dict for {key val} $dictval {
				if {$val eq "null" || $val eq ""} {
					:addNull $key
				} elseif {[string is integer -strict $val]} {
					:addInt $key $val
				} elseif {[string is double -strict $val] || [string is wideinteger $val]} {
					:addNumber $key $val
				} elseif {[string is boolean -strict $val]} {
					:addBool $key $val
				} else {
					:addString $key $val
				}
			}
		}

		# method for different datatypes values
		:public method addNull {key} {
			CkJsonObject_AddNullAt ${:json} -1 "$key"
		}
		
		:public method addInt {key value} {
			CkJsonObject_AddIntAt ${:json} -1 "$key" "$value"
		}
		
		:public method addNumber {key value} {
			CkJsonObject_AddNumberAt ${:json} -1 "$key" "$value"
		}
		
		:public method addBool {key value} {
			CkJsonObject_AddBoolAt ${:json} -1 "$key" "$value"
		}
		
		:public method addString {key value} {
			CkJsonObject_AddStringAt ${:json} -1 "$key" "$value"
		}
		
		# method to load and add json object from string
		:public method addObject {key value} {
			set jObj [new_CkJsonObject]
			CkJsonObject_put_Utf8 $jObj 1
			CkJsonObject_Load $jObj "$value"
			CkJsonObject_AddObjectCopyAt ${:json} -1 "$key" $jObj
			delete_CkJsonObject $jObj
		}

		# method to load and add json array from string
		:public method addArray {key value} {
			set jArr [new_CkJsonArray]
			CkJsonArray_put_Utf8 $jArr 1
			CkJsonArray_Load $jArr "$value"
			CkJsonObject_AppendArrayCopy ${:json} "$key" $jArr
			delete_CkJsonArray $jArr
		}

		:public method asJSON {} {
			CkJsonObject_put_EmitCompact ${:json} 0
			set res [CkJsonObject_emit ${:json}]
			return $res
		}
		
		:public method destroy {} {
			delete_CkJsonObject ${:json}
			next
		}
	}
}