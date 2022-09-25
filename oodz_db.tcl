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
				lappend result [ns_set array $rows]
			}
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
		}
	}
}

oodz_db create db