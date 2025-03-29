nx::Class create UpdateSQLBuilder {
    :property tableName:required       ;# Table to update
    :property {setDict ""}             ;# Key/value pairs to update
    :property {whereClause ""}         ;# WHERE condition string
    :property {columnTransforms ""}    ;# Optional column transformations

    :public method addRow {dataDict} {
        set :setDict $dataDict
    }

    :public method addData {key value} {
        dict set :setDict $key $value
    }

    :public method setWhereClause {where} {
        set :whereClause $where
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

    :public method buildQuery {} {
        if {[dict size ${:setDict}] == 0} {
            return -code error "No columns provided for UPDATE."
        }

        set assignments {}
        foreach {key value} ${:setDict} {
            lappend assignments "$key = [:formatValue $key $value]"
        }

        set query "UPDATE ${:tableName} SET [join $assignments ", "]"

        if {${:whereClause} ne ""} {
            append query " WHERE ${:whereClause}"
        }

        return $query
    }
}
