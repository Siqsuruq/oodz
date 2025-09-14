nx::Class create SQLBuilder {
    # Define the class variables
    :property tableName:required
    :property {columnsList ""}
    :property {whereClause ""}
    :property {joinList ""}
    :property {groupByList ""}
    :property {orderByList ""}
	:property {limit ""}
	:property {offset ""}

    # Define the addColumn method
    # :public method addColumn {columns} {
        # foreach column $columns {
            # lappend :columnsList $column
        # }
    # }
	:public method addColumn {columns} {
		foreach column $columns {
			# Split the column input into parts
			set parts [split $column " "]
			set partsCount [llength $parts]

			# Handle different scenarios based on the number of parts
			switch -- $partsCount {
				1 {
					# Single part, no alias
					lappend :columnsList $column
				}
				3 {
					# Three parts, expected to be 'columnName AS aliasName'
					if {[lindex $parts 1] eq "AS" || [lindex $parts 1] eq "as"} {
						lappend :columnsList [join $parts " "]
					} else {
						return -code error "Invalid column format: $column. Expected format 'columnName AS aliasName'."
					}
				}
				default {
					# Unsupported format
					return -code error "Invalid column format: $column. Expected format 'columnName' or 'columnName AS aliasName'."
				}
			}
		}
	}

    # Define the removeColumn method
    :public method removeColumn {columns} {
        foreach column $columns {
            set idx [lsearch ${:columnsList} $column]
            if {$idx != -1} {
                set :columnsList [lreplace ${:columnsList} $idx $idx]
            }
        }
    }

    # Define the addCondition method
    :public method addCondition {condition} {
        if {${:whereClause} eq ""} {
            set :whereClause $condition
        } else {
            append :whereClause " AND $condition"
        }
    }

	:public method addComplexCondition {condition {operator ""}} {
		# Check if an operator is provided
		if {$operator ne "" && ![string match "AND" $operator] && ![string match "OR" $operator]} {
			return -code error "Invalid logical operator: $operator. Must be 'AND', 'OR', or empty."
		}

		if {${:whereClause} eq ""} {
			# Directly set the condition if the whereClause is empty
			set :whereClause $condition
		} else {
			# Append the condition with the appropriate operator
			if {$operator eq "" || $operator eq "AND"} {
				append :whereClause " AND $condition"
			} elseif {$operator eq "OR"} {
				append :whereClause " OR $condition"
			}
		}
	}

    # Define the addJoin method
    :public method addJoin {joinType table joinCondition} {
        lappend :joinList [list $joinType $table $joinCondition]
    }

    # Define the addGroupBy method
    :public method addGroupBy {column} {
        lappend :groupByList $column
    }

    # Define the addOrderBy method
    :public method addOrderBy {columnOrders} {
        if {[expr {[llength $columnOrders] % 2}] != 0} {
            return -code error "Invalid input: columnOrders must contain pairs of column and order."
        }
        foreach {column order} $columnOrders {
			set order [string toupper $order]
			if {($order ne "ASC") && ($order ne "DESC")} {
				return -code error "Invalid sorting order: '$order'. Must be 'ASC' or 'DESC'."
			}
            lappend :orderByList [list $column $order]
        }
    }

    # Define the search method
    :public method search {term columns} {
        set conditions {}
        foreach column $columns {
			# ILIKE makes search case-insensitive and CAST to text more versatile in terms of the data types it can handle. However, may afect the performance of the search, especially if you're working with large datasets or complex data types.
			# Commented line is more general and will work with all databases and types
			# lappend conditions "$column LIKE '%$term%'"
            lappend conditions "CAST($column AS TEXT) ILIKE [ns_dbquotevalue %$term%]"
        }
        if {[llength $conditions] > 0} {
            set :whereClause [join $conditions " OR "]
        }
    }


    # Define the setLimit method
    :public method setLimit {limitValue} {
        set :limit $limitValue
    }

    # Define the setOffset method
    :public method setOffset {offsetValue} {
        set :offset $offsetValue
    }

    :public method addDateRange {column start end {kind "timestamptz"}} {
        if {$start eq "" || $end eq ""} {
            return -code error "addDateRange needs non-empty start and end"
        }
        set kind [string tolower $kind]
        if {$kind ni {date timestamp timestamptz}} {
            return -code error "Unsupported kind '$kind' (use date|timestamp|timestamptz)"
        }

        set s [ns_dbquotevalue $start]
        set e [ns_dbquotevalue $end]

        # Build full casted literals without triggering Tcl namespace parsing
        set startExpr "${s}::${kind}"
        set endExpr   "${e}::${kind}"

        :addComplexCondition "$column >= $startExpr AND $column < $endExpr" AND
    }

    # Define the clear method
	# Method that resets the SQLBuilder's properties related to LIMIT, OFFSET, ORDER BY, GROUP BY, and conditions (the WHERE clause)
    :public method clear {} {
        set :whereClause ""
        set :joinList ""
        set :groupByList ""
        set :orderByList ""
        set :limit ""
        set :offset ""
    }

    # Define the buildCountQuery method
    :public method buildCountQuery {} {
        set query "SELECT COUNT(*) FROM \"${:tableName}\""

        foreach join ${:joinList} {
            set joinType [lindex $join 0]
            set joinTable [lindex $join 1]
            set joinCondition [lindex $join 2]
            append query " $joinType JOIN $joinTable ON $joinCondition"
        }
        
        if {${:whereClause} ne ""} {
            append query " WHERE ${:whereClause}"
        }

        if {[llength ${:groupByList}] > 0} {
            set groupBy [join ${:groupByList} ", "]
            append query " GROUP BY $groupBy"
        }

        return $query
    }

    # Define the buildSelectQuery method
    :public method buildSelectQuery {} {
        set columns [join ${:columnsList} ", "]
        if {$columns eq ""} {
            set columns "*"
        }

        set query "SELECT $columns FROM \"${:tableName}\""

        foreach join ${:joinList} {
            set joinType [lindex $join 0]
            set joinTable [lindex $join 1]
            set joinCondition [lindex $join 2]
            append query " $joinType JOIN $joinTable ON $joinCondition"
        }
        
        if {${:whereClause} ne ""} {
            append query " WHERE ${:whereClause}"
        }

        if {[llength ${:groupByList}] > 0} {
            set groupBy [join ${:groupByList} ", "]
            append query " GROUP BY $groupBy"
        }

        if {[llength ${:orderByList}] > 0} {
			set orderBy [join ${:orderByList} ", "]
			append query " ORDER BY $orderBy NULLS LAST"
        }
		
		# Add the LIMIT clause
        if {${:limit} ne ""} {
            append query " LIMIT ${:limit}"
        }
        
        # Add the OFFSET clause
        if {${:offset} ne ""} {
            append query " OFFSET ${:offset}"
        }
		
        return $query
    }
}