namespace eval oodz {
	nx::Class create db -superclass superClass {
		# Possible result formats are: D - Tcl dict, L - Tcl list, J - JSON, default is Tcl dict
		:property {result_format "D"}
		
		:public method show_pg_version {} {
			set result ""
			set code "ok"
			set :db_handles [ns_db gethandle]
			set query "SELECT version();"
			try {
				set row [ns_db 0or1row ${:db_handles} $query]
				set result [dict getnull [ns_set array $row] version]
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}			
		}

		:public method current_database {} {
			set result ""
			set code "ok"
			set :db_handles [ns_db gethandle]
			set query "SELECT current_database();"
			try {
				set row [ns_db 0or1row ${:db_handles} $query]
				set result [dict getnull [ns_set array $row] current_database]
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}			
		}

		:public method table_exists {table} {
			set result 0
			set code "ok"
			set query "SELECT tbl_view_exists([ns_dbquotevalue $table])"
			set :db_handles [ns_db gethandle]
			try {
				set row [ns_db 0or1row ${:db_handles} $query]
				if {$row eq ""} {
					set result 0
				} else {
					if {[dict get [ns_set array $row] tbl_view_exists] eq "t"} {
						set result 1
					}
				}
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}

		:public method select_uuid_by_id {table id} {
			set result ""
			set code "ok"
			set :db_handles [ns_db gethandle]
			set query "SELECT uuid_${table} FROM $table WHERE id=[ns_dbquotevalue $id]"
			try {
				set row [ns_db 0or1row ${:db_handles} $query]
				set result [dict getnull [ns_set array $row] uuid_${table}]
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}

		:public method select_id_by_uuid {table uuid} {
			set result ""
			set code "ok"
			set :db_handles [ns_db gethandle]
			set query "SELECT id FROM $table WHERE uuid_${table}=[ns_dbquotevalue $uuid]"
			try {
				set row [ns_db 0or1row ${:db_handles} $query]
				set result [dict getnull [ns_set array $row] id]
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}

		:public method select_id_by_name {table name} {
			set result ""
			set code "ok"
			set :db_handles [ns_db gethandle]
			set query "SELECT id FROM $table WHERE name=[ns_dbquotevalue $name]"
			try {
				set rows [ns_db select ${:db_handles} $query]
				while {[ns_db getrow ${:db_handles} $rows]} {
					lappend result [dict get [ns_set array $rows] id]
				}
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}

		:public method select_uuid_by_name {table name} {
			set result ""
			set code "ok"
			set :db_handles [ns_db gethandle]
			set query "SELECT uuid_$table FROM $table WHERE name=[ns_dbquotevalue $name]"
			try {
				set rows [ns_db select ${:db_handles} $query]
				while {[ns_db getrow ${:db_handles} $rows]} {
					lappend result [dict get [ns_set array $rows] uuid_$table]
				}
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}
		
		:public method select_col_by_id {table column id} {
			set result ""
			set code "ok"
			set :db_handles [ns_db gethandle]
			set query "SELECT $column FROM $table WHERE id=[ns_dbquotevalue $id]"
			try {
				set row [ns_db 0or1row ${:db_handles} $query]
				set result [dict getnull [ns_set array $row] $column]
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}
		
		:public method select_col_by_uuid {table column uuid} {
			set result ""
			set code "ok"
			set :db_handles [ns_db gethandle]
			set query "SELECT [ns_dbquotevalue $column] FROM $table WHERE uuid_${table}=[ns_dbquotevalue $uuid]"
			try {
				set row [ns_db 0or1row ${:db_handles} $query]
				set result [dict getnull [ns_set array $row] $column]
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}
		
		:public method select_name_by_id {table id} {
			set result ""
			set code "ok"
			set :db_handles [ns_db gethandle]
			set query "SELECT name FROM $table WHERE id=[ns_dbquotevalue $id]"
			try {
				set row [ns_db 0or1row ${:db_handles} $query]
				set result [dict getnull [ns_set array $row] name]
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}
		
		:public method select_name_by_uuid {table uuid} {
			set result ""
			set code "ok"
			set :db_handles [ns_db gethandle]
			set query "SELECT name FROM $table WHERE uuid_${table}=[ns_dbquotevalue $uuid]"
			try {
				set row [ns_db 0or1row ${:db_handles} $query]
				set result [dict getnull [ns_set array $row] name]
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}
		
		:public method get_columns_types {table {columns "*"}} {
			set result ""
			set code "ok"
			set col_type [dict create]
			set :db_handles [ns_db gethandle]
			set query "SELECT * FROM information_schema.columns WHERE table_name = '$table'"
			try {
				set rows [ns_db select ${:db_handles} $query]
				while {[ns_db getrow ${:db_handles} $rows]} {
					dict append col_type [dict get [ns_set array $rows] column_name] [dict get [ns_set array $rows] data_type]
				}
				if {$columns eq "*"} {
					set result $col_type
				} else {
					foreach col $columns {
						lappend result [dict getnull $col_type $col]
					}
				}
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}
		
		# Release all db handlers
		:method release {} {
			foreach handle ${:db_handles} {
				ns_db releasehandle $handle
			}
		}

		:public method get {args} {
			switch [lindex $args 0] {
				pool {
					return ${:srv}pool1
				}
				pg_version {
					return [:show_pg_version]
				}
				result_format {
					return ${:result_format}
				}
			}
		}
		
		:public method select_columns_names {table} {
			set result ""
			set code "ok"
			set :db_handles [ns_db gethandle]
			set query "SELECT column_name FROM information_schema.columns WHERE table_name = '$table' AND table_schema='public' ORDER BY ordinal_position ASC"
			try {
				set rows [ns_db select ${:db_handles} $query]
				while {[ns_db getrow ${:db_handles} $rows]} {
					lappend result [dict get [ns_set array $rows] column_name]
				}
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}

		:public method get_columns_names {table} {
			set result ""
			set code "ok"
			set :db_handles [ns_db gethandle]
			# set query "SELECT column_name FROM information_schema.columns WHERE table_name = '$table' AND table_schema='public' ORDER BY ordinal_position ASC"
			set query "SELECT 
				c.column_name, 
				c.data_type,
				CASE 
					WHEN tc.constraint_type = 'FOREIGN KEY' THEN 'YES'
					ELSE 'NO'
				END AS is_foreign_key,
				CASE 
					WHEN tc.constraint_type = 'PRIMARY KEY' THEN 'YES'
					ELSE 'NO'
				END AS is_primary_key,
				CASE 
					WHEN c.column_default LIKE 'nextval%' THEN 'YES'
					ELSE 'NO'
				END AS is_auto_increment
			FROM 
				information_schema.columns c
			LEFT JOIN information_schema.key_column_usage kcu
				ON c.table_name = kcu.table_name
				AND c.column_name = kcu.column_name
				AND c.table_schema = kcu.table_schema
			LEFT JOIN information_schema.table_constraints tc
				ON kcu.constraint_name = tc.constraint_name
				AND kcu.table_schema = tc.table_schema
				AND (tc.constraint_type = 'FOREIGN KEY' OR tc.constraint_type = 'PRIMARY KEY')
			WHERE 
				c.table_name = '$table'
				AND c.table_schema = 'public';"
			try {
				set rows [ns_db select ${:db_handles} $query]
				set rows [ns_db select ${:db_handles} $query]
				# oodzLog notice "QUERY: $query"
				while {[ns_db getrow ${:db_handles} $rows]} {
					lappend result [ns_set array $rows]
				}
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}
		
		:method my_columns {table columns} {
			set my_columns [list]
			set my_tables [list $table]
			set fklist [list]

			foreach col $columns {
				if {[string match fk_* $col] == 1} {
					set trimmed_tbl_name [::textutil::trim::trim $col fk_]
					if {[lsearch -exact $my_tables "$trimmed_tbl_name"] == -1} {
						lappend my_tables [set fk_table $trimmed_tbl_name]
					}
					# lappend my_columns "$fk_table.name as $fk_table\_name"
					lappend my_columns "$fk_table.name AS $col"
					lappend fklist " $table.$col=$fk_table.id "
					# if {$search ne "" && $def_search_col ne ""} {
						# if {$def_search_col eq $col} {
							# set def_search_col $fk_table.name
						# }
					# }
				} elseif {[string match ufk_* $col] == 1} {
					set trimmed_tbl_name [::textutil::trim::trim $col ufk_]
					if {[lsearch -exact $my_tables "$trimmed_tbl_name"] == -1} {
						lappend my_tables [set fk_table $trimmed_tbl_name]
					}
					lappend my_columns "$fk_table.name as ${fk_table}_name"
					lappend my_columns $table.$col
					lappend fklist " $table.$col=$fk_table.uuid_${fk_table} "
				} else {
					lappend my_columns $table.$col
				}
			}
			# puts "MY COLUMNS: $my_columns"
			# puts "MY TABLES: $my_tables"
			# puts "MY FKLIST: $fklist"
			return [list $my_columns $my_tables $fklist]
		}
		
		:public method select_all2 {table {columns "*"}} {
			set result ""
			set code "ok"
			set sb [::SQLBuilder new -tableName $table]
			
			try {
				if {$columns == "*"} {
					set columns [: select_columns_names $table]
				}
				set :db_handles [ns_db gethandle]
				set result [$sb buildSelectQuery]
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				$sb destroy
				: release
				return -code $code $result
			}
		}

		:public method select_all {table {columns "*"} {extra "none"} args} {
			set result ""
			set code "ok"
			if {$columns == "*"} {
				set columns [: select_columns_names $table]
			}
			set :db_handles [ns_db gethandle]
		
			set params [lindex $args 0]
			
			if {[dict getnull $params sort] ne ""} {
				set sort [dict get $params sort]
			} else {set sort "id"}
			if {[dict getnull $params order] ne ""} {
				set order [string toupper [dict get $params order]]
			} else {set order "DESC"}
			if {[dict getnull $params offset] ne ""} {
				set offset [dict get $params offset]
			} else {set offset ""}
			if {[dict getnull $params limit] ne ""} {
				set limit [dict get $params limit]
			} else {set limit ""}
			if {[dict getnull $params search] ne ""} {
				set search [dict get $params search]
			} else {set search ""}
			if {[dict getnull $params def_search_col] ne ""} {
				set def_search_col [dict get $params def_search_col]
			} else {set def_search_col ""}
			# count rows parametr
			if {[dict getnull $params return_count] ne ""} {
				set return_count 1
			} else {set return_count 0}
			
			set a [: my_columns $table $columns]
			set my_columns [lindex $a 0]
			set my_tables [lindex $a 1]
			set fklist [lindex $a 2]
			# set my_columns [list]
			# set my_tables [list $table]
			# set fklist [list]

			# foreach col $columns {
				# if {[string match fk_* $col] == 1} {
					# set trimmed_tbl_name [::textutil::trim::trim $col fk_]
					# if {[lsearch -exact $my_tables "$trimmed_tbl_name"] == -1} {
						# lappend my_tables [set fk_table $trimmed_tbl_name]
					# }
					# # lappend my_columns "$fk_table.name as $fk_table\_name"
					# lappend my_columns "$fk_table.name as $col"
					# lappend fklist " $table.$col=$fk_table.id "
					# if {$search ne "" && $def_search_col ne ""} {
						# if {$def_search_col eq $col} {
							# set def_search_col $fk_table.name
						# }
					# }
				# } elseif {[string match ufk_* $col] == 1} {
					# set trimmed_tbl_name [::textutil::trim::trim $col ufk_]
					# if {[lsearch -exact $my_tables "$trimmed_tbl_name"] == -1} {
						# lappend my_tables [set fk_table $trimmed_tbl_name]
					# }
					# lappend my_columns "$fk_table.name as ${fk_table}_name"
					# lappend my_columns $table.$col
					# lappend fklist " $table.$col=$fk_table.uuid_${fk_table} "
				# } else {
					# lappend my_columns $table.$col
				# }
			# }
			# puts "MY COLUMNS: $my_columns"
			# puts "MY TABLES: $my_tables"
			# puts "MY FKLIST: $fklist"
			
			set query "SELECT "
			append query "[::csv::join $my_columns]"
			append query " FROM [::csv::join $my_tables] "
						
			if {[llength $fklist] != 0 && $extra != "none"} {
				append query " WHERE "
				append query [::csv::join $fklist AND]
				append query " AND $extra"
				if {$search ne "" && $def_search_col ne ""} {
					append query " AND CAST($def_search_col AS TEXT) ILIKE '$search%'"
				}
			} elseif {[llength $fklist] != 0 && $extra == "none"} {
				append query " WHERE "
				append query [::csv::join $fklist AND]
				if {$search ne "" && $def_search_col ne ""} {
					append query " AND CAST($def_search_col AS TEXT) ILIKE '$search%'"
				}
			} elseif {[llength $fklist] == 0 && $extra != "none"} {
				append query " WHERE "
				append query " $extra"
				if {$search ne "" && $def_search_col ne ""} {
					append query " AND CAST($def_search_col AS TEXT) ILIKE '$search%'"
				}
			} elseif {[llength $fklist] == 0 && $extra eq "none"} {
				if {$search ne "" && $def_search_col ne ""} {
					append query " WHERE CAST($def_search_col AS TEXT) ILIKE '$search%'"
				}
			}
			
			# Adding default ORDER BY
			if {$table ne "counter" && [lsearch $my_columns *.$sort] != -1} {
				append query " ORDER BY $sort $order NULLS LAST"
			}
			
			# Count rows in case return_count is not 0, it must be done before LIMIT and OFFSET
			if {$return_count != 0} {
				set count_query "SELECT COUNT(*) FROM ($query) AS return_count"
				set rows_count [ns_set array [ns_db 0or1row ${:db_handles} $count_query]]
			} 
			
			# LIMIT and OFFSET allow you to retrieve just a portion of the rows that are generated by the rest of the query
			if {$limit ne "" && $offset eq ""} {
				append query " LIMIT $limit"
			} elseif {$limit ne "" && $offset ne ""} {
				append query " LIMIT $limit OFFSET $offset"
			}
			
			oodzLog notice "QUERY: $query"
			try {
				if {${:result_format} eq "J"} {
					set query "SELECT json_agg(t) FROM ($query) t"
					oodzLog notice "QUERY: $query"
					
					set row [ns_db 0or1row ${:db_handles} $query]
					# oodzLog notice "ROW: $row"
					# oodzLog notice "ROW ARRAY: [ns_set array $row]"
					set result [dict get [ns_set array $row] json_agg]			
				} elseif {${:result_format} eq "L"} { 
					set rows [ns_db select ${:db_handles} $query]
					# oodzLog notice "QUERY: $query"
					while {[ns_db getrow ${:db_handles} $rows]} {
						set row [ns_set array $rows]
						lappend result [dict values $row]
					}
				} else {
					set rows [ns_db select ${:db_handles} $query]
					# oodzLog notice "QUERY: $query"
					while {[ns_db getrow ${:db_handles} $rows]} {
						lappend result [ns_set array $rows]
					}
				}
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}

		# data is a list of dictionaries
		:public method insert {table data {conflict ""} {returning ""} {nspace 1}} {
			set result ""
			set tbl_cols [: get_columns_types $table]
			set qb [InsertSQLBuilder new -tableName $table]
			try {
				foreach line $data {
					set tmpline [dict create]
					foreach col [dict keys $line] {
						# Checking if column exists, if not ignore it and save log
						if {[lsearch -exact [dict keys $tbl_cols] $col] != -1} {
							dict set tmpline $col [dict get $line $col]
						} else {
							oodzLog warning "Column ${table}.${col} does not exists"
						}
					}
					$qb addRow $tmpline
				}

				if {$returning eq ""} {
					if {[lsearch -exact [dict keys $tbl_cols] id] != -1 && [lsearch -exact [dict keys $tbl_cols] uuid_${table}] != -1} {
						$qb setReturningColumns [list id uuid_${table}]
					} elseif {[lsearch -exact [dict keys $tbl_cols] id] != -1} {
						$qb setReturningColumns [list id]
					}
				} else {
					$qb setReturningColumns $returning
				}
				
				set query "[$qb buildQuery]"
				set :db_handles [ns_db gethandle]
				set rows [ns_db select ${:db_handles} $query]
				while {[ns_db getrow ${:db_handles} $rows]} {
					lappend result [ns_set array $rows]
				}
				return -code ok $result
			} on error {errMsg} {
				return -code "error" "insert_all method: $errMsg"
			} finally {
				: release
			}
		}
		
		# Should always return inserted id and uuid get rid of returning empty, unless defined * ()return everything
		:public method insert_all {table data {conflict ""} {returning ""} {nspace 1}} {
			set result ""
			set code "ok"
			set tbl_cols [: get_columns_types $table]
			set my_columns [list]
			set my_values [list]
			foreach col [dict keys $data] {
				# Checking if column exists, if not ignore it and save log
				if {[lsearch -exact [dict keys $tbl_cols] $col] != -1} {
					lappend my_columns \"$col\"
					if {[string match fk_* $col] == 1} {
						if {[dict get $data $col] != ""} {
							lappend my_values [ns_dbquotevalue [: select_id_by_name [::textutil::trim::trim $col fk_] [dict get $data $col]]]
						} else {
							lappend my_values NULL
						}
					} else {
						if {[dict get $data $col] != ""} {
							if {[dict get $tbl_cols $col] eq "bytea"} {
								lappend my_values [ns_dbquotevalue [dict get $data $col]]
							} elseif {[dict get $tbl_cols $col] eq "ARRAY"} {
								set values_list ""
								set orig_values_list [dict get $data $col]
								foreach value $orig_values_list {
									lappend values_list [ns_dbquotevalue $value]
								}
								set arr "ARRAY\[[join $values_list ,]\]"
								lappend my_values $arr
							} else {
								if {$nspace != 1} {
									lappend my_values [ns_dbquotevalue [dict get $data $col]]
								} else {
									lappend my_values [ns_dbquotevalue [::oodz::Sanitize normalize_spaces [dict get $data $col]]]
								}
							}
						} else {
							lappend my_values NULL
						}
					}
				} else {oodzLog warning "Column ${table}.${col} does not exists"}
			}
			set query "INSERT INTO \"$table\" ([join $my_columns ,]) VALUES ([join $my_values ,])"
			if {$conflict ne ""} {
				append query " ON CONFLICT ([lindex $conflict 0]) DO [lindex $conflict 1]"
			}
			if {$returning ne ""} {
				if {$returning eq "*"} {
					append query { RETURNING *}
				} else {
					append query " RETURNING [join $returning ,]"
				}
			}
			oodzLog notice "QUERY: $query"
			try {
				set :db_handles [ns_db gethandle]
				if {$returning ne ""} {
					set query_res [ns_db 0or1row ${:db_handles} $query]
					if {$query_res ne ""} {
						foreach ret $returning {
							lappend result [dict get [ns_set array $query_res] $ret]
						}
					} 
				} else {
					ns_db dml ${:db_handles} $query
				}
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}

		:public method update_all {table data {nspace 1}} {
			set result ""
			set code "ok"
			set where [list]
			set my_values [list]
			set column_names [: select_columns_names $table]

			# Ensuring id key is the first in the columns list
			if {[dict exists $data id] == 1} {
				lappend where id='[dict get $data id]'
				set data [dict remove $data id]
			} elseif {[dict exists $data uuid_${table}] == 1} {
				lappend where uuid_${table}='[dict get $data uuid_${table}]'
				set data [dict remove $data uuid_${table}]
			}
			
			foreach col [dict keys $data] val [dict values $data] {
				if {[lsearch -exact $column_names $col] != -1} {
					if {[string match fk_* $col] == 1} {
						lappend my_values $col=[ns_dbquotevalue [: select_id_by_name [::textutil::trim::trim $col fk_] $val]]
					} else {
						if {$val != ""} {
							if {[: get_columns_types $table $col] eq "bytea"} {
								lappend my_values $col=[ns_dbquotevalue $val]
							} else {
								if {$nspace != 1} {
									lappend my_values $col=[ns_dbquotevalue $val]
								} else {
									lappend my_values $col=[ns_dbquotevalue [::oodz::Sanitize normalize_spaces $val]]
								}
							}
								
						} else {
							lappend my_values $col=NULL
						}
					}
				}
			}
			set query "UPDATE $table SET [::csv::join $my_values , ""] WHERE [lindex $where 0]"
			
			oodzLog notice "QUERY: $query"

			try {
				set :db_handles [ns_db gethandle]
				ns_db dml ${:db_handles} $query
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}
		########################################################## Delete ##########################################################
		# For compatibility, do not use for new code, will be removed in the future
		:public method delete_row {table ids} {
			: delete_rows $table $ids
		}
		
		:public method delete_rows {table ids} {
			set result ""
			set code "ok"
			try {
				set :db_handles [ns_db gethandle]
				set int_ids [list]
				set uuids_ids [list]
				foreach id $ids {
					if {[string is entier -strict $id] == 1} {
						lappend int_ids $id
					} elseif {[::oodz::DataType is_uuid $id] == 1} {
						lappend uuids_ids $id
					}
				}
				if {[llength $int_ids] > 0} {
					set query "DELETE FROM $table WHERE id IN ([::csv::join $int_ids , ""])"
				} elseif {[llength $uuids_ids] > 0} {
					set query "DELETE FROM $table WHERE uuid_${table} IN ([ns_dbquotelist $uuids_ids])"
				}
				ns_db dml ${:db_handles} $query
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}
		########################################################## hstore ##########################################################
		:public method update_hstore {table id data {col "extra"} {uuid_col ""}}  {
			set result ""
			set code "ok"
			set hst_data ""
			dict for {key val} $data {
				append hst_data "\"$key\"=>\"$val\","
			}
			set hst_data [string trimright $hst_data ,]
			
			if {[::oodz::DataType is_uuid ${id}] == 1} {
				if {$uuid_col eq ""} {
					set uuid_col uuid_${table}
				}
				set query "UPDATE $table SET $col = $col || ('$hst_data') ::hstore WHERE $table.$uuid_col='$id';"
			} else {
				set query "UPDATE $table SET $col = $col || ('$hst_data') ::hstore WHERE $table.id='$id';"
			}
			
			oodzLog notice "QUERY: $query"

			try {
				set :db_handles [ns_db gethandle]
				ns_db dml ${:db_handles} $query
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}
		
		:public method delete_hstore {table id key_2_del {col "extra"} {uuid_col ""}} {
			set result ""
			set code "ok"
			if {[::oodz::DataType is_uuid ${id}] == 1} {
				if {$uuid_col eq ""} {
					set uuid_col uuid_${table}
				}
				set query "UPDATE $table SET $col = delete($col, '$key_2_del') WHERE $table.$uuid_col='$id';"
			} else {
				set query "UPDATE $table SET $col = delete($col, '$key_2_del') WHERE $table.id='$id';"
			}
			oodzLog notice "QUERY: $query"
			try {
				set :db_handles [ns_db gethandle]
				ns_db dml ${:db_handles} $query
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}
		
		:public method get_hstore_dict {table id {col "extra"} {uuid_col ""}} {
			set result ""
			set code "ok"
			if {[::oodz::DataType is_uuid ${id}] == 1} {
				if {$uuid_col eq ""} {
					set uuid_col uuid_${table}
				}
				set query "SELECT hstore_to_json($col) FROM $table WHERE $table.$uuid_col='$id';"
			} else {
				set query "SELECT hstore_to_json($col) FROM $table WHERE id='$id';"
			}
			oodzLog notice "QUERY: $query"
			try {
				set :db_handles [ns_db gethandle]
				set row [ns_db 0or1row ${:db_handles} $query]
				if {$row ne ""} {
					set result [::json::json2dict [dict get [ns_set array $row] hstore_to_json]]
				} 
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}
		
		# For backward compatibility, do not use. Use: get_hstore_dict
		:public method get_hstore_dict_uuid {table uuid {col "extra"} {uuid_col ""}} {
			return [: get_hstore_dict $table $uuid $col $uuid_col]
		}
		
		:public method get_hstore_val {table id vals {col "extra"} {uuid_col ""}} {
			set result ""
			set hstrdict [: get_hstore_dict $table $id $col $uuid_col]
			foreach val $vals {
				dict append result $val [dict getnull $hstrdict $val]
			}
			return $result
		}
		
		
	###################################### Execute Query #################################################
		:public method execute_query {args} {
			set result ""
			set code "ok"
			set query [lindex $args 0]
			oodzLog notice "QUERY: $query"

			try {
				set :db_handles [ns_db gethandle]
				
				if {${:result_format} eq "J"} {
					set query "SELECT json_agg(t) FROM ($query) t"
					set result [dict getnull [ns_set array [ns_db 0or1row ${:db_handles} $query]] json_agg]
				} else {
					set query_res [ns_db exec ${:db_handles} $query]
					if {$query_res eq "NS_ROWS"} {
						set rows [ns_db bindrow ${:db_handles}]
						while {[ns_db getrow ${:db_handles} $rows]} {
							lappend result [ns_set array $rows]
						}
					} 
				}
			} on error {e} {
				oodzLog error "DB ERROR: $e"
				set code "error"
				set result $e
			} finally {
				: release
				return -code $code $result
			}
		}
	}
}
