nx::Class create htmlWrapper -superclass oodz_superclass {
	# default div class name is main
	:property {frame "main"}
	:property module:required
	:property args

	:method init {} {
		set xml_file [file join [ns_pagepath] [set ${:srv}::mod_dir] ${:module} ]
		return $xml_file
		# set doc [dom parse [tdom::xmlReadFile $xml_file]]
		# set hd "[$doc asXML]"
		# ::htmlparse::parse -cmd [list html_wrapper main $module] $hd
	}
	
	
	:public method html_wrapper {args} {
		foreach a $args {
			lappend ar_l [string trim $a]
		}
		set tag [lindex $ar_l 0]
		set tagsgn [lindex $ar_l 1]
		set props [lindex $ar_l 2]
		set val [lindex $ar_l 3]
		set a [lindex $ar_l 4]	
	}


	:public method print {} {
		return [${:obj1} get data]
	}
}