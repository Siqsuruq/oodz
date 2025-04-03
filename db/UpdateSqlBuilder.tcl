nx::Class create UpdateSQLBuilder {
    :property tableName:required       ;# Table to update
    :property {setDict ""}             ;# Key/value pairs to update
    :property {whereList {}}           ;# List of {column operator value}
    :property {columnTransforms ""}    ;# Optional column transformations

    :public method addRow {dataDict} {
        set :setDict $dataDict
    }

    :public method addData {key value} {
        dict set :setDict $key $value
    }

    :public method addWhere {column operator value} {
        lappend :whereList [list $column $operator $value]
    }

    :public method setColumnTransform {column exprTemplate} {
        dict set :columnTransforms $column $exprTemplate
    }

    :method formatValue {column value} {
        if {[dict exists ${:columnTransforms} $column]} {
            set template [dict get ${:columnTransforms} $column]
            set quotedValue [ns_dbquotevalue $value]
            return [string map [list ? $quotedValue] $template]
        }
        return [ns_dbquotevalue $value]
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

    :public method buildQuery {} {
        if {[dict size ${:setDict}] == 0} {
            return -code error "No columns provided for UPDATE."
        }

        set assignments {}
        foreach {key value} ${:setDict} {
            lappend assignments "$key = [:formatValue $key $value]"
        }

        set query "UPDATE ${:tableName} SET [join $assignments ", "]"

        if {[llength ${:whereList}] > 0} {
            set conditions {}
            foreach clause ${:whereList} {
                lassign $clause column operator value
                lappend conditions [:formatWhereCondition $column $operator $value]
            }
            append query " WHERE [join $conditions " AND "]"
        }

        return $query
    }
}