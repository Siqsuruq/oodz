nx::Class create DeleteSQLBuilder {
    # Define the class variables
    :property tableName:required
    :property {whereClause ""}
    :property {joinList ""}
    :property {limit ""}
    :property {offset ""}

    # Define the addCondition method
    :public method addCondition {condition} {
        if {${:whereClause} eq ""} {
            set :whereClause $condition
        } else {
            append :whereClause " AND $condition"
        }
    }

    # Define the addComplexCondition method
    :public method addComplexCondition {condition {operator ""}} {
        if {$operator ne "" && ![string match "AND" $operator] && ![string match "OR" $operator]} {
            return -code error "Invalid logical operator: $operator. Must be 'AND', 'OR', or empty."
        }

        if {${:whereClause} eq ""} {
            set :whereClause $condition
        } else {
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

    # Define the setLimit method
    :public method setLimit {limitValue} {
        set :limit $limitValue
    }

    # Define the setOffset method
    :public method setOffset {offsetValue} {
        set :offset $offsetValue
    }

    # Define the clear method
    :public method clear {} {
        set :whereClause ""
        set :joinList ""
        set :limit ""
        set :offset ""
    }

    # Define the buildDeleteQuery method
    :public method buildDeleteQuery {} {
        if {${:tableName} eq ""} {
            return -code error "Table name is required to build a DELETE query."
        }

        set query "DELETE FROM ${:tableName}"

        foreach join ${:joinList} {
            set joinType [lindex $join 0]
            set joinTable [lindex $join 1]
            set joinCondition [lindex $join 2]
            append query " $joinType JOIN $joinTable ON $joinCondition"
        }

        if {${:whereClause} ne ""} {
            append query " WHERE ${:whereClause}"
        }

        if {${:limit} ne ""} {
            append query " LIMIT ${:limit}"
        }

        if {${:offset} ne ""} {
            append query " OFFSET ${:offset}"
        }

        return $query
    }
}
