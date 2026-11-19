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
    :property {valid_columns ""}
    :property {table_name ""}

    :method init {} {
        if {${:table_name} ne ""} {
            try {
                set :valid_columns [::db select_columns_names ${:table_name}]
                return -code ok
            } on error {errMsg} {
                return -code error $errMsg
            }
        }
    }

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
            set filteredColumns [dict create]
            dict for {colIdx column} $columnsDict {
                if {[dict exists $column data]} {
                    set colName [dict get $column data]
                    if {[lsearch -exact ${:valid_columns} $colName] != -1} {
                        dict set filteredColumns $colIdx $column
                    }
                }
            }
            # Store only valid columns
            set :columns $filteredColumns
            # Inject order info only into valid filtered columns
            dict for {idx orderEntry} $orderDict {
                if {
                    [dict exists $orderEntry column] &&
                    [dict exists $orderEntry dir]
                } {
                    set colIdx [dict get $orderEntry column]
                    set dir [string tolower [dict get $orderEntry dir]]
                    if {$dir ni {asc desc}} {
                        set dir asc
                    }
                    if {[dict exists ${:columns} $colIdx]} {
                        set column [dict get ${:columns} $colIdx]
                        dict set column order_direction $dir
                        dict set column order_index $idx
                        dict set :columns $colIdx $column
                    }
                }
            }
            set :order_columns_indx $orderDict
            :pagination
            :order
            :search
            :result
            return -code ok ${:result}
        } on error {errMsg} {
            ::oodzLog error "Class=datatablesClass method=parse_datatable_request error=$errMsg"
            return -code error $errMsg
        }
    }

    # Compose :result dict
    :method result {} {
        dict set :result columns ${:columns}
        dict set :result search ${:global_search}
        dict set :result search_columns ${:search_columns}
        dict set :result order_columns ${:order_list}
        return -code ok ${:result}
    }

    :method order {} {
        set :order_list ""
        dict for {key value} ${:order_columns_indx} {
            if {![dict exists $value column]} {
                continue
            }
            set colIdx [dict get $value column]
            if {![dict exists ${:columns} $colIdx]} {
                continue
            }
            set columnDict [dict get ${:columns} $colIdx]
            if {![dict exists $columnDict data]} {
                continue
            }
            set col [dict get $columnDict data]
            if {[lsearch -exact ${:valid_columns} $col] == -1} {
                continue
            }
            set dir [dict getnull $value dir]
            set dir [string tolower $dir]
            if {$dir ni {asc desc}} {
                set dir asc
            }
            lappend :order_list $col $dir
        }
        return -code ok
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

    :public method build_query {tableName {translate ""} {rowKey ""}} {
        set :valid_columns [::db select_columns_names $tableName]
        if {$rowKey ne "" && [lsearch -exact ${:valid_columns} $rowKey] == -1} {
            return -code error "Row key '$rowKey' is not a column of table '$tableName'"
        }
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
            set query [$sb buildSelectQuery]
            # Expose the row key as DT_RowId so DataTables Editor can address rows.
            if {$rowKey ne ""} {
                set query "SELECT t.*, t.${rowKey} AS \"DT_RowId\" FROM ($query) t"
            }
            if {$translate ne ""} {
                set rows [db execute_query $query]
                set js_lines_arr [::oodz::nsJsonArray new]
                try {
                    foreach row $rows {
                        foreach column $translate {
                            if {![dict exists $row $column]} {
                                continue
                            }
                            set value [dict get $row $column]
                            if {$value eq ""} {
                                continue
                            }
                            dict set row $column [::msgcat::mc $value]
                        }
                        set jsObj [::oodz::JsonObj new]
                        try {
                            $jsObj addDict $row
                            $js_lines_arr addObject [$jsObj asJSON]
                        } finally {
                            $jsObj destroy
                        }
                    }
                    set a [$js_lines_arr asJSON]
                } finally {
                    $js_lines_arr destroy
                }
            } else {
                set a [dbj execute_query $query]
            }
            set recordsFiltered [dict getnull [lindex [db execute_query [$sb buildCountQuery]] 0] count]
            if {$a eq ""} {
                set a "\[\]"
            }
            set res "{\"recordsTotal\": $recordsTotal,\"recordsFiltered\": $recordsFiltered,\"data\": $a}"
            return -code ok $res
        } on error {errMsg} {
            ::oodzLog error "Class=datatablesClass method=build_query error=$errMsg"
            return -code error $errMsg
        } finally {
            $sb destroy
        }
    }

    # Normalise the Editor "data" payload.
    # JSON requests arrive as a nested dict; form-encoded requests arrive as flat
    # keys such as data[0][name]. Returns a dict of rowId -> {column value}.
    :method editor_payload {req} {
        set nested [dict getnull $req data]
        if {[dict exists $req data] && [catch {dict size $nested}] == 0 && [dict size $nested] > 0} {
            return $nested
        }
        set result [dict create]
        foreach key [dict keys $req] {
            if {![regexp {^data\[([^\]]+)\]\[([^\]]+)\]$} $key -> rowId col]} {
                continue
            }
            set rowData [dict getnull $result $rowId]
            dict set rowData $col [dict get $req $key]
            dict set result $rowId $rowData
        }
        return $result
    }

    # Server side handler for DataTables Editor requests.
    # tableName and editable must come from server side configuration, never from the client.
    # Any column not present in both lists is rejected, and ::db helpers quote/bind values.
    :public method editor_process {tableName editable {idColumn "id"}} {
        try {
            set valid [::db select_columns_names $tableName]
            foreach col [lsort -unique [concat $editable $idColumn]] {
                if {[lsearch -exact $valid $col] == -1} {
                    return -code error "Column '$col' is not a column of table '$tableName'"
                }
            }
            set action [dict getnull ${:req} action]
            set payload [: editor_payload ${:req}]
            if {$payload eq ""} {
                return -code error "No data in request"
            }
            set changed {}
            switch -- $action {
                create {
                    foreach {_idx rowData} $payload {
                        set clean [dict create]
                        foreach col $editable {
                            if {[dict exists $rowData $col]} {
                                dict set clean $col [dict get $rowData $col]
                            }
                        }
                        if {[dict size $clean] == 0} {
                            continue
                        }
                        set newId [lindex [::db insert_all $tableName $clean "" [list $idColumn]] 0]
                        if {$newId eq ""} {
                            continue
                        }
                        dict set clean $idColumn $newId
                        dict set clean DT_RowId $newId
                        lappend changed $clean
                    }
                }
                edit {
                    foreach rowId [dict keys $payload] {
                        set rowData [dict get $payload $rowId]
                        set clean [dict create $idColumn $rowId]
                        foreach col $editable {
                            if {[dict exists $rowData $col]} {
                                dict set clean $col [dict get $rowData $col]
                            }
                        }
                        if {[dict size $clean] < 2} {
                            continue
                        }
                        ::db update_all $tableName $clean
                        dict set clean DT_RowId $rowId
                        lappend changed $clean
                    }
                }
                remove {
                    ::db delete_rows $tableName [dict keys $payload]
                }
                default {
                    return -code error "Unsupported editor action '$action'"
                }
            }
            return -code ok [: editor_json $changed]
        } on error {errMsg} {
            ::oodzLog error "Class=datatablesClass method=editor_process error=$errMsg"
            return -code error $errMsg
        }
    }

    # Build the {"data":[...]} body expected by DataTables Editor.
    :method editor_json {rows} {
        set arr [::oodz::nsJsonArray new]
        try {
            foreach row $rows {
                set obj [::oodz::JsonObj new]
                try {
                    $obj addDict $row
                    $arr addObject [$obj asJSON]
                } finally {
                    $obj destroy
                }
            }
            set inner [$arr asJSON]
            if {$inner eq ""} {
                set inner "\[\]"
            }
            return "{\"data\":$inner}"
        } finally {
            $arr destroy
        }
    }
}
