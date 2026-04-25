namespace eval ::oodz {
    nx::Class create nsJsonArray -superclass nsJson {
        :method init {} {
            next
            set :json [list "" array [list]]
        }

        :method appendValue {type value} {
            set content [lindex ${:json} 2]
            set idx [expr {[llength $content] / 3}]
            lappend content $idx $type $value
            set :json [list "" array $content]
            return [self]
        }

        :public method addNull {} {
            try {
                return [: appendValue null {}]
            } on error {errMsg} {
                return -code error "$errMsg"
            }
        }

        :public method addString {value} {
            try {
                return [: appendValue string $value]
            } on error {errMsg} {
                return -code error "$errMsg"
            }
        }

        :public method addInt {value} {
            try {
                if {![string is integer -strict $value]} {
                    return -code error "Value '$value' is not a valid integer."
                }
                return [: appendValue number $value]
            } on error {errMsg} {
                return -code error "$errMsg"
            }
        }

        :public method addNumber {value} {
            try {
                if {![::oodz::DataType is_number $value]} {
                    return -code error "Value '$value' is not a valid number."
                }
                return [: appendValue number $value]
            } on error {errMsg} {
                return -code error "$errMsg"
            }
        }

        :public method addBool {value} {
            try {
                return [: appendValue boolean [::oodz::DataType to_bool $value]]
            } on error {errMsg} {
                return -code error "$errMsg"
            }
        }

        
        :public method addObject {value} {
            try {
                set parsed [ns_json parse -output triples $value]
                if {[lindex $parsed 1] ne "object"} {
                    return -code error "Error loading JSON object: value is not a JSON object."
                }
                return [: appendValue object [lindex $parsed 2]]
            } on error {errMsg} {
                return -code error "Error loading JSON object: $errMsg"
            }
        }

        :public method getSize {} {
            set content [lindex ${:json} 2]
            return [expr {[llength $content] / 3}]
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

       :public method getObject {index} {
            try {
                set content [lindex ${:json} 2]
                foreach {k t v} $content {
                    if {$k == $index} {
                        if {$t ne "object"} {
                            return -code error "Error getting JSON object at index $index: value is not an object."
                        }
                        return -code ok [list "" object $v]
                    }
                }
                return -code error "Error getting JSON object at index $index: index not found."
            } on error {errMsg} {
                return -code error "Error getting JSON object at index $index: $errMsg"
            }
        }

        :public method Load {jsonStr} {
            try {
                set parsed [ns_json parse -output triples $jsonStr]
                if {[lindex $parsed 1] ne "array"} {
                    return -code error "Error loading JSON array: JSON is not an array."
                }
                set :json $parsed
                return -code ok
            } on error {errMsg} {
                return -code error "Error loading JSON array: $errMsg"
            }
        }
    }
}	