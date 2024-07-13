namespace eval oodz {
	nx::Class create db2 -superclass superClass {
		# Possible result formats are: D - Tcl dict, L - Tcl list, J - JSON, default is Tcl dict
		:property {result_format "D"}
		
		:public method dbName {} {
			set result [dict create]
			set :db_handles [ns_db gethandle]
			try {
				dict set result data [ns_pg db ${:db_handles}]
				dict set result error [ns_pg error ${:db_handles}]
				dict set result status [ns_pg status ${:db_handles}]
			} trap {} {arr} {
				oodzLog error "DB ERROR: $arr"
			} finally {
				: release
				return $result
			}			
		}
		
		# Release all db handlers
		:method release {} {
			foreach handle ${:db_handles} {
				ns_db releasehandle $handle
			}
		}
		
		:public method select_columns_names {table} {
			set result [list]
			set :db_handles [ns_db gethandle]
			set data [ns_set create table $table]
			set query "SELECT column_name FROM information_schema.columns WHERE table_name = :table AND table_schema='public' ORDER BY ordinal_position ASC"
			try {
				set rows [ns_pg_bind select ${:db_handles} -bind $data $query]
				while {[ns_db getrow ${:db_handles} $rows]} {
					lappend result [dict get [ns_set array $rows] column_name]
				}
			} trap {} {arr} {
				oodzLog error "DB ERROR: $arr"
				set result [ns_pg error ${:db_handles}]
			} finally {
				: release
				return $result
			}
		}
		
		:public method select_all {table {columns "*"} {extra "none"} args} {
			set result ""
			set data [ns_set create table $table]
			set sql [SQLBuilder new -table $table]
			if {$columns == "*"} {
				set columns [: select_columns_names $table]
			}
			set :db_handles [ns_db gethandle]
			
			foreach col $columns {
				if {[string match fk_* $col] == 1} {
					set fk_table [::textutil::trim::trim $col fk_]
					$sql addColumn [list "${fk_table}.name AS ${col}_name"]
					$sql addJoin "LEFT" $fk_table "$table.$col=$fk_table.id"
				} elseif {[string match ufk_* $col] == 1} {
					set fk_table [::textutil::trim::trim $col ufk_]
					$sql addColumn [list "${fk_table}.name AS ${col}_name"]
					$sql addJoin "LEFT" $fk_table "$table.$col = $fk_table.uuid_${fk_table} "
				} else {
					$sql addColumn $table.$col
				}
			}

			set params [lindex $args 0]
			puts "*****************"
			puts $params
			puts "******************"
			
			# if {[dict getnull $params sort] ne ""} {
				# set sort [dict get $params sort]
			# } else {set sort "id"}
			
			# if {[dict getnull $params order] ne ""} {
				# set order [string toupper [dict get $params order]]
			# } else {set order "DESC"}
			
			# LIMIT, OFFSET
			if {[dict getnull $params offset] ne ""} {
				$sql setOffset [dict get $params offset]
			}
			if {[dict getnull $params limit] ne ""} {
				$sql setLimit [dict get $params limit]
			}
			
			# if {[dict getnull $params search] ne ""} {
				# set search [dict get $params search]
			# } else {set search ""}
			# if {[dict getnull $params def_search_col] ne ""} {
				# set def_search_col [dict get $params def_search_col]
			# } else {set def_search_col ""}
			
			# Count rows parameter
			if {[dict getnull $params return_count] ne ""} {
				set return_count 1
			} else {set return_count 0}
			
			# set a [: my_columns $table $columns]
			# set my_columns [lindex $a 0]
			# set my_tables [lindex $a 1]
			# set fklist [lindex $a 2]
			
			if {$extra != "none"} {

			}
			
			# set query "SELECT "
			# append query "[::csv::join $my_columns]"
			# append query " FROM [::csv::join $my_tables] "
						
			# if {[llength $fklist] != 0 && $extra != "none"} {
				# append query " WHERE "
				# append query [::csv::join $fklist AND]
				# append query " AND $extra"
				# if {$search ne "" && $def_search_col ne ""} {
					# append query " AND CAST($def_search_col AS TEXT) ILIKE '$search%'"
				# }
			# } elseif {[llength $fklist] != 0 && $extra == "none"} {
				# append query " WHERE "
				# append query [::csv::join $fklist AND]
				# if {$search ne "" && $def_search_col ne ""} {
					# append query " AND CAST($def_search_col AS TEXT) ILIKE '$search%'"
				# }
			# } elseif {[llength $fklist] == 0 && $extra != "none"} {
				# append query " WHERE "
				# append query " $extra"
				# if {$search ne "" && $def_search_col ne ""} {
					# append query " AND CAST($def_search_col AS TEXT) ILIKE '$search%'"
				# }
			# } elseif {[llength $fklist] == 0 && $extra eq "none"} {
				# if {$search ne "" && $def_search_col ne ""} {
					# append query " WHERE CAST($def_search_col AS TEXT) ILIKE '$search%'"
				# }
			# }
			
			# # Adding default ORDER BY
			# if {$table ne "counter" && [lsearch $my_columns *.$sort] != -1} {
				# append query " ORDER BY $sort $order NULLS LAST"
			# }
			
			# # Count rows in case return_count is not 0, it must be done before LIMIT and OFFSET
			# if {$return_count != 0} {
				# set count_query "SELECT COUNT(*) FROM ($query) AS return_count"
				# set rows_count [ns_set array [ns_db 0or1row ${:db_handles} $count_query]]
			# } 
			
			# LIMIT and OFFSET allow you to retrieve just a portion of the rows that are generated by the rest of the query
			# if {$limit ne "" && $offset eq ""} {
				# append query " LIMIT $limit"
			# } elseif {$limit ne "" && $offset ne ""} {
				# append query " LIMIT $limit OFFSET $offset"
			# }
			
			# oodzLog notice "QUERY: $query"
			set query [$sql buildSelectQuery]
			try {
				# if {${:result_format} eq "J"} {
					# set query "SELECT json_agg(t) FROM ($query) t"
					# set row [ns_pg_bind 0or1row ${:db_handles} -bind $data $query]

					# set result [dict get [ns_set array $row] json_agg]			
				# } elseif {${:result_format} eq "L"} { 
					# set rows [ns_pg_bind select ${:db_handles} -bind $data $query]
					# while {[ns_db getrow ${:db_handles} $rows]} {
						# set row [ns_set array $rows]
						# puts $row
						# lappend result [dict values $row]
					# }
				# } else {
					# set rows [ns_pg_bind select ${:db_handles} -bind $data $query]
					# # oodzLog notice "QUERY: $query"
					# while {[ns_db getrow ${:db_handles} $rows]} {
						# lappend result [ns_set array $rows]
					# }
				# }
			} trap {} {arr} {
				oodzLog error "DB ERROR: $arr"
			} finally {
				: release
				$sql destroy
				return $query
			}
		}
	
	}
}