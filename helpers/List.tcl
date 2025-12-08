namespace eval oodz {
    ::nx::Object create listObj {
        # Will be substituted with lremove from Tcl 9 in the future
        :public object method remove_from_list {original rem_list} {
            try {
                set stripped $original
                foreach rval $rem_list {
                    set stripped [lsearch -inline -all -not -exact $stripped $rval]
                }
                return -code ok $stripped
            } on error {errMsg} {
                return -code error "Method remove_from_list: $errMsg"
            }
        }

        # Converts a list to a dictionary where keys are the indices
        :public object method enum_2_dict {list_2_enum} {
            try {
                set res [dict create]
                for {set i 0} {$i < [llength $list_2_enum]} {incr i} {
                    dict set res $i [lindex $list_2_enum $i]
                }
                return -code ok $res
            } on error {errMsg} {
                return -code error "Method enum_2_dict: $errMsg"
            }
        }

        # Compares two lists and returns the elements in the first list that are not in the second list
        :public object method listcomp {a b} {
            try {
                set diff {}
                foreach i $a {
                    if {[lsearch -exact $b $i]==-1} {
                        lappend diff $i
                    }
                }
                return -code ok $diff
            } on error {errMsg} {
                return -code error "Method listcomp: $errMsg"
            }
        }

        # Removes empty strings from a list 
        :public object method remove_empty_from_list {my_list} {
            try {
                set non_empty [struct::list filter [struct::list flatten $my_list] {apply {{x} {expr {[string length $x] > 0}}}}]
                return -code ok $non_empty
            } on error {errMsg} {
                return -code error "Method remove_empty_from_list: $errMsg"
            }
        }

        # Shuffles a list randomly
        :public object method shuffle_list { list_2_shuffle } {
            set newlist [list]
            foreach element $list_2_shuffle {
                lappend newlist [list [expr { rand() }] $element]
            }
            set retval [list]
                foreach pair [lsort -real -index 0 $newlist] {
                    foreach { random item } $pair {
                        lappend retval $item
                    }
                }
            return $retval
        }
    }
}