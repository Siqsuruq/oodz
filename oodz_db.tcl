nx::Class create oodz_db -superclass oodz_superclass {
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