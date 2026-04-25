namespace eval ::oodz {
	nx::Class create nsJsonObject -superclass nsJson {
        :method init {} {
            next
            # canonical root-wrapped triples for empty JSON object
            set :json [list "" object [list]]
        }

        :method upsert {key type value} {
            set content [lindex ${:json} 2]
            set newContent [list]
            set replaced 0
            foreach {k t v} $content {
                if {$k eq $key} {
                    lappend newContent $key $type $value
                    set replaced 1
                } else {
                    lappend newContent $k $t $v
                }
            }
            if {!$replaced} {
                lappend newContent $key $type $value
            }
            set :json [list "" object $newContent]
            return [self]
        }

        :public method addDict {dictval} {
            try {
                dict for {key val} $dictval {
                    if {$val eq "null" || $val eq ""} {
                        :addNull $key
                    } elseif {[::oodz::DataType is_number $val]} {
                        if {[string is integer -strict $val]} {
                            :addInt $key $val
                        } else {
                            :addNumber $key $val
                        }
                    } elseif {[::oodz::DataType is_bool $val]} {
                        :addBool $key $val
                    } else {
                        :addString $key $val
                    }
                }
                return [self]
            } on error {errMsg} {
                return -code error "$errMsg"
            }
        }

        :public method addNull {key} {
            try {
                return [: upsert $key null {}]
            } on error {errMsg} {
                return -code error "$errMsg"
            }
        }

        :public method addString {key value} {
            try {
                return [: upsert $key string $value]
            } on error {errMsg} {
                return -code error "$errMsg"
            }
        }

        :public method addInt {key value} {
            try {
                if {![string is integer -strict $value]} {
                    return -code error "Value '$value' is not a valid integer."
                }
                return [: upsert $key number $value]
            } on error {errMsg} {
                return -code error "$errMsg"
            }
        }

        :public method addNumber {key value} {
            try {
                if {![string is integer -strict $value] && ![string is wideinteger -strict $value] && ![string is double -strict $value]} {
                    return -code error "Value '$value' is not a valid number."
                }
                return [: upsert $key number $value]
            } on error {errMsg} {
                return -code error "$errMsg"
            }
        }

        :public method addBool {key value} {
            try {
                return [: upsert $key boolean [::oodz::DataType to_bool $value]]
            } on error {errMsg} {
                return -code error "$errMsg"
            }
        }

        :public method addObject {key value} {
            try {
                set parsed [ns_json parse -output triples $value]
                if {[lindex $parsed 1] ne "object"} {
                    return -code error "Error loading JSON object: value is not a JSON object."
                }
                return [:upsert $key object [lindex $parsed 2]]
            } on error {errMsg} {
                return -code error "Error loading JSON object: $errMsg"
            }
        }

        :public method addArray {key value} {
            try {
                set parsed [ns_json parse -output triples $value]

                if {[lindex $parsed 1] ne "array"} {
                    return -code error "Error loading JSON array: value is not a JSON array."
                }
                return [:upsert $key array [lindex $parsed 2]]
            } on error {errMsg} {
                return -code error "Error loading JSON array: $errMsg"
            }
        }

        :public method Load {jsonStr} {
            try {
                set parsed [ns_json parse -output triples $jsonStr]
                # ensure it's an object (since this is nsJsonObject)
                if {[lindex $parsed 1] ne "object"} {
                    return -code error "JSON is not an object."
                }
                set :json $parsed
                return [self]
            } on error {errMsg} {
                return -code error "Error loading JSON: $errMsg"
            }
        }

        :public method asJSON {} {
            try {
                if {${:json} eq ""} {
                    return ""
                }
                return [ns_json value -pretty ${:json}]
            } on error {errMsg} {
                return -code error "$errMsg"
            }
        }
    }
}