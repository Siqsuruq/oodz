nx::Class create oodz_db -superclass oodz_superclass {
	# Possible result formats are: D - Tcl dict, L - Tcl list, J - JSON, default is Tcl dict
	:property {result_format "D"}
	
	:method init {} {
		set :db [ns_db gethandle ${:srv}pool1 1]
	
	}
	
	:public method table_exists {args} {
		set table_name [lindex $args 0]
		set query "SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename  = [pg_quote $table_name])"
		set :db_handles [ns_db gethandle ${:srv}pool1 1]
		set row [ns_db 0or1row ${:db_handles} $query]
		if {$row eq ""} {
			set result 0
		} else {
			if {[dict get [ns_set array $row] exists] eq "t"} {
				set result 1
			} else {
				set result 0
			}
		}
		: release
		return $result
	}

	:public method select_uuid_by_id {table id} {
		set result ""
		set :db_handles [ns_db gethandle ${:srv}pool1 1]
		set query "SELECT uuid_${table} FROM $table WHERE id=[pg_quote $id]"
		try {
			set row [ns_db 0or1row ${:db_handles} $query]
			set result [ns_set array $row]
		} trap {} {arr} {
			oodzLog error "DB ERROR: $arr"
		} finally {
			: release
			return [dict getnull $result uuid_${table}]
		}
	}

	:public method select_id_by_uuid {table uuid} {
		set result ""
		set :db_handles [ns_db gethandle ${:srv}pool1 1]
		set query "SELECT id FROM $table WHERE uuid_${table}=[pg_quote $uuid]"
		try {
			set row [ns_db 0or1row ${:db_handles} $query]
			set result [ns_set array $row]
		} trap {} {arr} {
			oodzLog error "DB ERROR: $arr"
		} finally {
			: release
			return [dict getnull $result id]
		}
	}

	:public method select_id_by_name {table name} {
		set result ""
		set :db_handles [ns_db gethandle ${:srv}pool1 1]
		set query "SELECT id FROM $table WHERE name=[pg_quote $name]"
		try {
			set rows [ns_db select ${:db_handles} $query]
			while {[ns_db getrow ${:db_handles} $rows]} {
				lappend result [dict get [ns_set array $rows] id]
			}
		} trap {} {arr} {
			oodzLog error "DB ERROR: $arr"
		} finally {
			: release
			return $result
		}
	}

	:public method select_uuid_by_name {table name} {
		set result ""
		set :db_handles [ns_db gethandle ${:srv}pool1 1]
		set query "SELECT uuid_$table FROM $table WHERE name=[pg_quote $name]"
		try {
			set rows [ns_db select ${:db_handles} $query]
			while {[ns_db getrow ${:db_handles} $rows]} {
				lappend result [dict get [ns_set array $rows] uuid_$table]
			}
		} trap {} {arr} {
			oodzLog error "DB ERROR: $arr"
		} finally {
			: release
			return $result
		}
	}
	
	:public method select_col_by_id {table column id} {
		set result ""
		set :db_handles [ns_db gethandle ${:srv}pool1 1]
		set query "SELECT $column FROM $table WHERE id=[pg_quote $id]"
		try {
			set row [ns_db 0or1row ${:db_handles} $query]
			set result [ns_set array $row]
		} trap {} {arr} {
			oodzLog error "DB ERROR: $arr"
		} finally {
			: release
			return [dict getnull $result $column]
		}
	}
	
	:public method select_col_by_uuid {table column uuid} {
		set result ""
		set :db_handles [ns_db gethandle ${:srv}pool1 1]
		set query "SELECT $column FROM $table WHERE uuid_${table}=[pg_quote $uuid]"
		try {
			set row [ns_db 0or1row ${:db_handles} $query]
			set result [ns_set array $row]
		} trap {} {arr} {
			oodzLog error "DB ERROR: $arr"
		} finally {
			: release
			return [dict getnull $result $column]
		}
	}
	
	:public method select_name_by_id {table id} {
		set result ""
		set :db_handles [ns_db gethandle ${:srv}pool1 1]
		set query "SELECT name FROM $table WHERE id=[pg_quote $id]"
		try {
			set row [ns_db 0or1row ${:db_handles} $query]
			set result [ns_set array $row]
		} trap {} {arr} {
			oodzLog error "DB ERROR: $arr"
		} finally {
			: release
			return [dict getnull $result name]
		}
	}
	
	:public method select_name_by_uuid {table uuid} {
		set result ""
		set :db_handles [ns_db gethandle ${:srv}pool1 1]
		set query "SELECT name FROM $table WHERE uuid_${table}=[pg_quote $uuid]"
		try {
			set row [ns_db 0or1row ${:db_handles} $query]
			set result [ns_set array $row]
		} trap {} {arr} {
			oodzLog error "DB ERROR: $arr"
		} finally {
			: release
			return [dict getnull $result name]
		}
	}
	
	:public method get_columns_types {table {columns "*"}} {
		set col_type [dict create]
		set :db_handles [ns_db gethandle ${:srv}pool1 1]
		set query "SELECT * FROM information_schema.columns WHERE table_name = '$table'"
		try {
			set rows [ns_db select ${:db_handles} $query]
			while {[ns_db getrow ${:db_handles} $rows]} {
				dict append col_type [dict get [ns_set array $rows] column_name] [dict get [ns_set array $rows] data_type]
			}
		} trap {} {arr} {
			oodzLog error "DB ERROR: $arr"
		} finally {
			: release
			if {$columns eq "*"} {
				return [dict values $col_type]
			} else {
				set a ""
				foreach col $columns {
					lappend a [dict getnull $col_type $col]
				}
				return $a
			}
		}
	}
	
	# Release all db handlers
	:method release {} {
		foreach handle ${:db_handles} {
			ns_db releasehandle $handle
		}
	}

	:method pg_version {} {
		set :db_handles [ns_db gethandle ${:srv}pool1 1]
		set res [list]

		set row [ns_db 0or1row ${:db_handles} "SELECT version();"]
		if {$row eq ""} {
			set result 0
		} else {
			set result [ns_set array $row]			
		}
		: release
		return $result
	}

	:public method get {args} {
		switch [lindex $args 0] {
			pool {
				return ${:srv}pool1
			}
			pg_version {
				return : pg_version
			}
			result_format {
				return ${:result_format}
			}
		}
	}
	
	:public method select_columns_names {table} {
		set result ""
		set :db_handles [ns_db gethandle ${:srv}pool1 1]
		set query "SELECT column_name FROM information_schema.columns WHERE table_name = '$table' AND table_schema='public' ORDER BY ordinal_position ASC"
		try {
			set rows [ns_db select ${:db_handles} $query]
			while {[ns_db getrow ${:db_handles} $rows]} {
				lappend result [dict get [ns_set array $rows] column_name]
			}
		} trap {} {arr} {
			oodzLog error "DB ERROR: $arr"
		} finally {
			: release
			return $result
		}
	}
	
	:public method select_all {table {columns "*"} {extra "none"} {res_type "dict"} args} {
		set result ""
		if {$columns == "*"} {
			set columns [: select_columns_names $table]
		}
		set :db_handles [ns_db gethandle ${:srv}pool1 1]
		# set db0 [lindex ${:db_handles} 0]
		# set db1 [lindex ${:db_handles} 1]
	
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
		
		set my_columns [list]
		set my_tables [list $table]
		set fklist [list]

		foreach col $columns {
			if {[string match fk_* $col] == 1} {
				lappend my_tables [set fk_table [::textutil::trim::trim $col fk_]]
				# lappend my_columns "$fk_table.name as $fk_table\_name"
				lappend my_columns "$fk_table.name as $col"
				lappend fklist " $table.$col=$fk_table.id "
				if {$search ne "" && $def_search_col ne ""} {
					if {$def_search_col eq $col} {
						set def_search_col $fk_table.name
					}
				}
			} else {
				lappend my_columns $table.$col
			}
		}
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
				oodzLog notice "ROW: $row"
				oodzLog notice "ROW ARRAY: [ns_set array $row]"
				set result [dict get [ns_set array $row] json_agg]			
			} else {
				set rows [ns_db select ${:db_handles} $query]
				# oodzLog notice "QUERY: $query"
				while {[ns_db getrow ${:db_handles} $rows]} {
					lappend result [ns_set array $rows]
				}
			}
		} trap {} {arr} {
			oodzLog error "DB ERROR: $arr"
		} finally {
			: release
			return $result
		}
	}
}

oodz_db create db
db copy dbj
dbj configure -result_format J