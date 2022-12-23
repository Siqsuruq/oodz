nx::Class create htmlWrapper -superclass oodz_conf_global {
	:property {conf:object,required}
	:property {frame "main"}
	:property module:required
	:property xmlFile:required

	:method init {} {
		set xml_file [file join [ns_pagepath] [${:conf} get_global mod_dir] ${:module} ${:xmlFile} ]
		puts $xml_file
		set doc [dom parse [tdom::xmlReadFile $xml_file]]
		set hd "[$doc asXML]"
		puts $hd
		::htmlparse::parse -cmd [list [: html_wrapper main ${:module}]] $hd
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
		puts "HELLO: $tag $tagsgn $props $val $a"
		ns_adp_puts  "$tag <form><br>"
	}



}