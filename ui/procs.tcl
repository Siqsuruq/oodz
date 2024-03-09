proc handle_form {args} {
	puts "CALLING handle_form WITH $args"
	set m [ns_conn method]
	set r [ns_getform]
	set data [dict create]
	if {$m eq "GET"} {
		dict set data module [ns_set iget $r mod "base"]
		dict set data xml [ns_set iget $r xml ""]
	} elseif {$m eq "POST"} {
		set dd [ns_set array $r]
		puts "DD: $dd"
		set dz_cmd [dict getnull $dd dz_cmd]
		if {$dz_cmd ne ""} {
			$dz_cmd [dict unset dd dz_cmd]
		}
	}
	return $data
}

