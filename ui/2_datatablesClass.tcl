nx::Class create datatablesClass {
	:property req:required
	:property {result ""}
	:property {columns ""}
	:property {search_columns ""}
	:property {order_list ""}
	:property {order_columns ""}
	:property {order_columns_indx ""}
	:property {global_search ""}
	:property {global_search_regex 0}
	
	:public method parse_datatable_request {} {
		foreach key [dict keys ${:req}] {
			if {[regexp {columns\[\d+\]} $key] == 1} {
				set matches [regexp -all -inline {columns\[(\d+)\]\[(\w+)\]} $key]
				dict set :columns [lindex $matches 2]_[lindex $matches 1] [dict get ${:req} $key]
			}

			if {[regexp {search\[value\]} $key] == 1} {
				set :global_search [dict get ${:req} $key]
			}
			
			if {[regexp {order\[(\d+)\]\[(\w+)\]} $key] == 1} {
				lappend :order_columns_indx [dict get ${:req} $key]
			}
		}
		

		: pagination
		: parse_colummns_data
		: order
		dict set :result columns ${:columns}
		dict set :result search ${:global_search}
		dict set :result search_columns ${:search_columns}
		dict set :result order_columns ${:order_columns}
		return ${:result}
	}
	
	:method order {} {
		foreach idx [dict keys ${:order_columns_indx}] val [dict values ${:order_columns_indx}] {
			set col_name [lindex ${:order_list} $idx]
			dict set :order_columns $col_name $val
		}
	}
	
	:method parse_colummns_data {} {
		dict for {key value} ${:columns} {
			if {[string match -nocase {data_*} $key] == 1} {

			}
			
			if {[string match -nocase {name_*} $key] == 1} {

			}
			
			if {[string match -nocase {searchable_*} $key] == 1} {
				if {[dict get ${:columns} $key] eq "true"} {
					set indx [string trimleft $key "searchable_"]
					lappend :search_columns [dict get ${:columns} data_${indx}]
				}
				dict unset :columns $key
			}
			
			if {[string match -nocase {orderable_*} $key] == 1} {
				if {[dict get ${:columns} $key] eq "true"} {
					set indx [string trimleft $key "orderable_"]
					lappend :order_list [dict get ${:columns} data_${indx}]
				}
				dict unset :columns $key
			}
		}
	}
	
	:method pagination {} {
		if {[dict getnull ${:req} length] != -1} {
			dict set :result LIMIT [dict getnull ${:req} length]
		}
		dict set :result OFFSET [dict getnull ${:req} start]
	}

}