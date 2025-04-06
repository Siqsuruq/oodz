nx::Class create InsertSQLBuilder {
    :property tableName:required  ;# Name of the table to insert into (required)
    :property {rowsList ""}         ;# List of dictionaries (rows) to insert
    :property {returningColumns ""}
    :property {columnTransforms ""} ;# Optional transforms like pgp_sym_encrypt
    :property {conflictTarget ""} ;# Columns to use for conflict resolution
    :property {conflictAction ""} ;# Action on conflict (default: DO NOTHING)
    :property {updateOnConflictColumns ""} ;# Columns to update on conflict
    :property {conflictWhereList {}} ;# List of {column operator value}


    # Method to add a single row (as a dictionary)
    :public method addRow {rowDict} {
        lappend :rowsList $rowDict
    }

    # Method to clear all rows
    :public method clear {} {
        set :rowsList ""
    }

    # Method to set returning columns
    :public method setReturningColumns {columns} {
        set :returningColumns $columns
    }

    :public method setConflictAction {action} {
        set :conflictAction $action
    }

    :public method setColumnTransform {column exprTemplate} {
        dict set :columnTransforms $column $exprTemplate
    }

    :public method setConflictTarget {columns} {
        set :conflictTarget $columns
    }

    :public method setUpdateOnConflictColumns {columns} {
        set :updateOnConflictColumns $columns
    }

    :public method addConflictWhere {column operator value} {
        lappend :conflictWhereList [list $column $operator $value]
    }

    :method formatWhereCondition {column operator value} {
        set op [string toupper $operator]
        switch -- $op {
            "IN" - "NOT IN" {
                set values [join [lmap v $value { ns_dbquotevalue $v }] ", "]
                return "$column $op ($values)"
            }
            default {
                return "$column $op [ns_dbquotevalue $value]"
            }
        }
    }

    :method formatValue {column value} {
        if {[dict exists ${:columnTransforms} $column]} {
            set template [dict get ${:columnTransforms} $column]
            set quotedValue [ns_dbquotevalue $value]
            return [string map [list ? $quotedValue] $template]
        }
        return [ns_dbquotevalue $value]
    }

    :public method buildQuery {} {
        if {[llength ${:rowsList}] == 0} {
            return -code error "No rows provided for the INSERT query."
        }

        set columns [dict keys [lindex ${:rowsList} 0]]

        foreach rowDict ${:rowsList} {
            if {[dict keys $rowDict] ne $columns} {
                return -code error "All rows must have the same columns for an INSERT query."
            }
        }

        set valuesList {}
        foreach rowDict ${:rowsList} {
            set rowValues {}
            foreach column $columns {
                set value [dict get $rowDict $column]
                lappend rowValues [:formatValue $column $value]
            }
            lappend valuesList "([join $rowValues ", "])"
        }

        set valuesStr [join $valuesList ", "]
        set query "INSERT INTO ${:tableName} ([join $columns ", "]) VALUES $valuesStr"

        if {[llength ${:returningColumns}] > 0} {
            append query " RETURNING [join ${:returningColumns} ", "]"
        }

        # Add ON CONFLICT support if specified
        if {${:conflictTarget} ne ""} {
            append query " ON CONFLICT ([join ${:conflictTarget} ", "])"
            if {${:conflictAction} eq "nothing"} {
                append query " DO NOTHING"
            } elseif {${:conflictAction} eq "update"} {
                set updateParts {}
                set updateCols ${:updateOnConflictColumns}
                if {[llength $updateCols] == 0} {
                    set updateCols $columns
                }
                foreach column $updateCols {
                    lappend updateParts "$column = EXCLUDED.$column"
                }
                append query " DO UPDATE SET [join $updateParts ", "]"
                if {[llength ${:conflictWhereList}] > 0} {
                    set whereClauses {}
                    foreach clause ${:conflictWhereList} {
                        lassign $clause column operator value
                        lappend whereClauses [:formatWhereCondition $column $operator $value]
                    }
                    append query " WHERE [join $whereClauses " AND "]"
                }
            }
        }

        return $query
    }
}