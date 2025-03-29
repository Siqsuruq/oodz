nx::Class create InsertSQLBuilder {
    # Define the class properties
    :property tableName:required  ;# Name of the table to insert into (required)
    :property {rowsList ""}         ;# List of dictionaries (rows) to insert
    :property {returningColumns ""}
    :property {columnTransforms ""} ;# Optional transforms like pgp_sym_encrypt

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

        return $query
    }
}