namespace eval oodz {
	nx::Class create dateTime -superclass ::oodz::baseClass {
		:property {oodzConf:object,required}
		
		:method init {} {
			set :date_format [oodzConf get_global date_format]
			set :timezone [oodzConf get_global timezone]
			set :time_hm_format [oodzConf get_global time_hm_format]
			set :now_date_time_format [oodzConf get_global now_date_time_format]
			set :time_format [oodzConf get_global time_format]
			set :timestamp_format [oodzConf get_global timestamp_format]
		}

		:public method date {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format ${:date_format} -timezone "${:timezone}"]
		}
		
		:public method ISO_date {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format %Y-%m-%d -timezone "${:timezone}"]
		}

		:public method ISO_year_month {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format %Y-%m -timezone "${:timezone}"]
		}
		
		:public method ISO_time {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format %H:%M:%S -timezone "${:timezone}"]
		}

		:public method ISO_timestamp {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format "%Y-%m-%d %H:%M:%S" -timezone "${:timezone}"]
		}

		:public method year {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format %Y -timezone "${:timezone}"]
		}
		
		:public method month {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format %m -timezone "${:timezone}"]
		}

		:public method six_digit_date {} {
			set systemTime [clock seconds]
			return [string range [clock format $systemTime -format %Y%m%d -timezone "${:timezone}"] 2 end]
		}
		
		:public method six_digit_time {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format %H%M%S -timezone "${:timezone}"]
		}

		:public method string_timestamp {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format %Y%m%d%H%M%S -timezone "${:timezone}"]
		}

		:public method yesterday {} {
			return [clock format [clock scan "yesterday"] -format ${:date_format}]
		}

		:public method today {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format ${:date_format} -timezone "${:timezone}"]
		}

		:public method ISO_today {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format %Y-%m-%d -timezone "${:timezone}"]
		}
		
		:public method ISO_now {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format %H:%M -timezone "${:timezone}"]
		}

		:public method tomorrow {} {
			return [clock format [clock scan "tomorrow"] -format ${:date_format}]
		}

		:public method time {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format ${:time_format} -timezone "${:timezone}"]
		}

		:public method time_hm {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format ${:time_hm_format} -timezone "${:timezone}"]
		}

		:public method now_date_time {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format ${:now_date_time_format} -timezone "${:timezone}"]
		}

		:public method day_of_week {{date ""}} {
			if {$date eq ""} {
				set systemTime [clock seconds]
			} else {
				set systemTime [clock scan "$date"]
			}
			return [::msgcat::mc "[clock format $systemTime -format %A -timezone "${:timezone}"]"]
		}

		:public method make_timestamp {{dt ""} {tm ""}} {
			if {$dt eq "" && $tm eq ""} {
				return "[: ISO_date] [: ISO_time]"
			} elseif {$dt ne "" && $tm eq ""} {
				return "$dt [: ISO_time]"
			} elseif {$dt eq "" && $tm ne ""} {
				return "[: ISO_date] $tm"
			} else {
				return "$dt $tm"
			}
		}

		:public method timestamp {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format "${:timestamp_format}" -timezone "${:timezone}"]
		}

		:public method months {days} {
			set month 30.4
			return [expr {round($days / $month)}]
		}

		:public method now_date {what} {
			set systemTime [clock seconds]
			if {$what eq "year"} {
				return [clock format $systemTime -format "%Y" -timezone "${:timezone}"]
			} elseif {$what eq "month"} {
				return [clock format $systemTime -format "%B" -timezone "${:timezone}"]
			}
		}

		# :public method every {ms body} {
			# eval $body
			# after $ms [list every $ms $body]
		# }

		# Compare 2 dates and return earlier date first
		:public method compare_dates {date1 date2} {
			set d1 [clock scan "$date1"]
			set d2 [clock scan "$date2"]
			if { [expr { $date1 < $date2 }] } {
				return [list $date1 $date2]
			} else {
				return [list $date2 $date1]
			}
		}

		# Returns boolean value 1 if timestamp in range, 0 if out of range
		:public method in_range {date1 range range_unit date2} {
			set range_start [clock scan "$date1"]
			set range_stop [clock add $range_start $range $range_unit]
			set date_in_range [clock scan "$date2"]
			if { $date_in_range >= $range_start && $date_in_range <= $range_stop } {
				return 1
			} else {
				return 0
			}
		}

		:public method is_it_now {date_future} {
			set now [clock scan [: date]]
			set fut [clock scan $date_future]
			if {[expr {$now < $fut}]} {
				return 0
			} else {return 1}

		}

		:public method age {date} {
			set now [clock format [clock scan now] -format %Y]
			return [expr $now - [clock format [clock scan $date -format ${:date_format}] -format %Y]]
		}

		# init_date MUST BE ISO_date
		:public method date_add {val val_type action {init_date ""}} {
			if {$init_date eq ""} {
				set init_date [: ISO_date]
			}
			return [clock format [clock add [clock scan $init_date -format %Y-%m-%d] $action$val $val_type] -format %Y-%m-%d -timezone "${:timezone}"]
		}

		# :public method get_country_timezone {args} {
			# set srv [srv_info]
			# set query "SELECT country.nicename, timezone.zone_name FROM country LEFT JOIN timezone ON timezone.country_code = country.iso WHERE nicename='[lindex $args 0]' ORDER BY timezone.country_code ASC"
			# return [execute_qry $query]
		# }

		:public method digit_month_2_abbr {args} {
			set month_num [lindex $args 0]
			set abr_m [dict create 1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dez"]
			if {$month_num ne ""} {
				return [dict getnull $abr_m $month_num ]
			} else {
				return ""
			}
		}
		
		:public method seconds_to_human {seconds} {
			# Handle months differently, assuming 30.44 days per month for calculation
			# Given the small number, it's more practical to start from days for readability
			set days [expr {$seconds / (86400)}]
			set hours [expr {($seconds % 86400) / 3600}]
			set minutes [expr {($seconds % 3600) / 60}]
			set secs [expr {$seconds % 60}]

			# Building the readable format string
			set readable ""

			if {$days > 0} {
				append readable "${days} days "
			}
			if {$hours > 0} {
				append readable "${hours} hours "
			}
			if {$minutes > 0} {
				append readable "${minutes} minutes "
			}
			append readable "${secs} seconds"

			return [string trim $readable]
		}
		
		:public method extract {ISO_date what} {
			if {$ISO_date ne "" } {
				if {$what eq "year" || $what eq "y"} {
					return [clock format $ISO_date -format %Y]
				}
			}
		}

		:public method ISO_to_local {{iso_date_time ""}} {
			# Remove milliseconds and 'Z' for compatibility
			regsub {(\.\d+)?Z$} $iso_date_time "" clean_timestamp
			# Parse the timestamp in UTC
			set epochTime [clock scan $clean_timestamp -format "%Y-%m-%dT%H:%M:%S" -gmt false]
			return [clock format $epochTime -format "%Y-%m-%d %H:%M:%S" -timezone "${:timezone}"]
		}

		:public method db_to_local_date {db_timestamp} {
			# Convert database timestamp (2025-11-04 23:25:29) to Cape Verde date
			set epochTime [clock scan $db_timestamp -format "%Y-%m-%d %H:%M:%S" -timezone "UTC"]
			return [clock format $epochTime -format "%Y-%m-%d" -timezone "${:timezone}"]
		}

		:public method db_to_local_time {db_timestamp} {
			# Convert database timestamp (2025-11-04 23:25:29) to Cape Verde time
			set epochTime [clock scan $db_timestamp -format "%Y-%m-%d %H:%M:%S" -timezone "UTC"]
			return [clock format $epochTime -format "%H:%M:%S" -timezone "${:timezone}"]
		}

		:public method db_to_local_datetime {db_timestamp} {
			# Convert database timestamp to Cape Verde date and time
			set epochTime [clock scan $db_timestamp -format "%Y-%m-%d %H:%M:%S" -timezone "UTC"]
			return [clock format $epochTime -format "%Y-%m-%d %H:%M:%S" -timezone "${:timezone}"]
		}
	}
}
