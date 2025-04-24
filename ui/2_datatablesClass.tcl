nx::Class create datatablesClass {
    :property req:required
    :property {result ""}
    :property {columns ""}
    :property {search_columns ""}
    :property {order_list ""}
    :property {order_columns_indx ""}
    :property {global_search ""}
    :property {global_search_regex 0}
    :property {limit ""}
    :property {offset ""}

:public method parse_datatable_request {} {
    try {
        set columnsDict [dict create]
        set orderDict [dict create]

        foreach key [dict keys ${:req}] {
            set val [dict get ${:req} $key]
            # Build columns dict
            if {[regexp {^columns\[(\d+)\]\[(\w+)\]$} $key -> colIdx prop]} {
                set column [dict getnull $columnsDict $colIdx]
                dict set column $prop $val
                dict set columnsDict $colIdx $column
                continue
            }

            # Build order[i] → dict
            if {[regexp {^order\[(\d+)\]\[(\w+)\]$} $key -> ordIdx prop]} {
                set order [dict getnull $orderDict $ordIdx]
                dict set order $prop $val
                dict set orderDict $ordIdx $order
                continue
            }

            if {[string equal $key "search\[value\]"]} {
                set :global_search $val
                continue
            }

            if {[string equal $key "search\[regex\]"]} {
                set :global_search_regex $val
                continue
            }
        }

        # Inject order info into corresponding columns
        dict for {idx orderEntry} $orderDict {
            if {
                [dict exists $orderEntry column] &&
                [dict exists $orderEntry dir]
            } {
                set colIdx [dict get $orderEntry column]
                set dir [dict get $orderEntry dir]
                set column [dict getnull $columnsDict $colIdx]
                if {$column ne ""} {
                    dict set column order_direction $dir
                    dict set column order_index $idx
                    dict set columnsDict $colIdx $column
                }
            }
        }

        # Store dicts directly into instance properties
        set :columns $columnsDict
        set :order_columns_indx $orderDict
        
        :pagination
        :order
        :search
        :result
        return -code ok ${:result}
    } on error {errMsg} {
        return -code error "Method parse_datatable_request: $errMsg"
    }
}

    # Compose :result dict
    :method result {} {
        dict set :result columns ${:columns}
        dict set :result search ${:global_search}
        dict set :result search_columns ${:search_columns}
        return -code ok ${:result}
    }

    :method order {} {
        dict for {key value} ${:order_columns_indx} {
            set col [dict get [dict get ${:columns} [dict get $value column]] data]
            lappend :order_list $col [dict get $value dir]
        }
    }

    :method search {} {
        dict for {key value} ${:columns} {
            if {[dict exists $value searchable] == 1 && [dict get $value searchable] eq "true"} {
                lappend :search_columns [dict get $value data]
            }	
        }
    }

    :method pagination {} {
        if {[dict getnull ${:req} length] != -1} {
            set :limit [dict getnull ${:req} length]
            dict set :result LIMIT ${:limit}
        }
        set :offset [dict getnull ${:req} start]
        dict set :result OFFSET ${:offset}
    }

    :public method build_query {tableName} {
        :parse_datatable_request
        set sb [SQLBuilder new -tableName $tableName]
        try {
            set recordsTotal [dict getnull [lindex [db execute_query [$sb buildCountQuery]] 0] count]
                
            if {${:global_search} ne "" && ${:search_columns} ne ""} {
                $sb search ${:global_search} ${:search_columns}
            }
            ############## Pagination ###################### 
            $sb setLimit ${:limit}
            $sb setOffset ${:offset}
            ################################################
            $sb addOrderBy ${:order_list}

            set a [dbj execute_query [$sb buildSelectQuery]]
            set recordsFiltered [dict getnull [lindex [db execute_query [$sb buildCountQuery]] 0] count]
            if {$a eq ""} {
                set res "{ \"recordsTotal\": $recordsTotal , \"recordsFiltered\" : $recordsFiltered, \"data\" : \[\]}"
            } else {
                set res "{ \"recordsTotal\": $recordsTotal , \"recordsFiltered\" : $recordsFiltered, \"data\" : $a }"
            }
            return -code ok $res
        } on error {errMsg} {
            return -code error "Method build_query: $errMsg"
        } finally {
            $sb destroy
        }
    }
}
