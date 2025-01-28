package require nx

nx::Class create InsertBuilder {
    # Define the class properties
    :property tableName:required  ;# Name of the table to insert into (required)
    :property {rowsList ""}         ;# List of dictionaries (rows) to insert
    :property {returningColumns ""}

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

    # Helper method to format a value for SQL using ns_dbquotevalue
    :method formatValue {value} {
        # Use ns_dbquotevalue to escape and quote the value
        return [ns_dbquotevalue $value]
    }

    # Method to build the INSERT query (handles both single and batch inserts)
    :public method buildQuery {} {
        if {[llength ${:rowsList}] == 0} {
            return -code error "No rows provided for the INSERT query."
        }

        # Extract columns from the first row (assume all rows have the same columns)
        set columns [dict keys [lindex ${:rowsList} 0]]

        # Validate that all rows have the same columns
        foreach rowDict ${:rowsList} {
            if {[dict keys $rowDict] ne $columns} {
                return -code error "All rows must have the same columns for an INSERT query."
            }
        }

        # Build the values part of the query
        set valuesList {}
        foreach rowDict ${:rowsList} {
            set rowValues {}
            foreach column $columns {
                lappend rowValues [:formatValue [dict get $rowDict $column]]
            }
            lappend valuesList "([join $rowValues ", "])"
        }
        set valuesStr [join $valuesList ", "]

        # Construct the INSERT query
        set query "INSERT INTO ${:tableName} ([join $columns ", "]) VALUES $valuesStr"
        # Add RETURNING clause if returningColumns is set
        if {[llength ${:returningColumns}] > 0} {
            append query " RETURNING [join ${:returningColumns} ", "]"
        }
        return $query
    }
}