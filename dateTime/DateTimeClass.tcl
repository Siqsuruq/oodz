namespace eval oodz {
	nx::Class create dateTime -superclass ::oodz::baseClass {
		:property {oodzConf:object,required}
		
		:method init {} {
			set :date_format [${:oodzConf} get_module_config date_time.date_format]
			set :timezone [${:oodzConf} get_module_config date_time.timezone]
			set :time_hm_format [${:oodzConf} get_module_config date_time.time_hm_format]
			set :now_date_time_format [${:oodzConf} get_module_config date_time.now_date_time_format]
			set :time_format [${:oodzConf} get_module_config date_time.time_format]
			set :timestamp_format [${:oodzConf} get_module_config date_time.timestamp_format]
		}

		############################################## General ##############################################
		:public method date {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format ${:date_format} -timezone "${:timezone}"]
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
			set systemTime [clock scan "yesterday" -timezone ${:timezone}]
			return [clock format $systemTime -format ${:date_format} -timezone ${:timezone}]
		}

		:public method today {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format ${:date_format} -timezone "${:timezone}"]
		}

		:public method tomorrow {} {
			set systemTime [clock scan "tomorrow" -timezone ${:timezone}]
			return [clock format $systemTime -format ${:date_format} -timezone ${:timezone}]
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

		:public method timestamp {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format "${:timestamp_format}" -timezone "${:timezone}"]
		}

		:public method now_date {what} {
			set systemTime [clock seconds]
			if {$what eq "year"} {
				return [clock format $systemTime -format "%Y" -timezone "${:timezone}"]
			} elseif {$what eq "month"} {
				return [clock format $systemTime -format "%B" -timezone "${:timezone}"]
			}
		}

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

		:public method months {days} {
			set month 30.4
			return [expr {round($days / $month)}]
		}

		:public method day_of_week {{date ""}} {
			if {$date eq ""} {
				set systemTime [clock seconds]
			} else {
				set systemTime [clock scan "$date" -timezone ${:timezone}]
			}
			return [::msgcat::mc "[clock format $systemTime -format %A -timezone "${:timezone}"]"]
		}
		############################################## ISO ##############################################
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
		
		:public method ISO_yesterday {} {
			set systemTime [clock scan "yesterday" -timezone ${:timezone}]
			return [clock format $systemTime -format "%Y-%m-%d" -timezone ${:timezone}]
		}

		:public method ISO_today {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format %Y-%m-%d -timezone "${:timezone}"]
		}
		
		:public method ISO_now {} {
			set systemTime [clock seconds]
			return [clock format $systemTime -format %H:%M -timezone "${:timezone}"]
		}

		# Compare 2 dates and return earlier date first. date1 and date2 MUST be ISO dates: YYYY-MM-DD
		:public method compare_dates {date1 date2} {
			set d1 [clock scan $date1 -format "%Y-%m-%d" -timezone ${:timezone}]
			set d2 [clock scan $date2 -format "%Y-%m-%d" -timezone ${:timezone}]
			if { [expr { $date1 <= $date2 }] } {
				return [list $date1 $date2]
			} else {
				return [list $date2 $date1]
			}
		}

		# Returns 1 if date2 is inside date1 + range, otherwise 0. date1/date2 MUST be ISO dates: YYYY-MM-DD
		:public method date_in_range {date1 range range_unit date2} {
			set range_start [clock scan $date1 -format "%Y-%m-%d" -timezone ${:timezone}]
			set range_stop [clock add $range_start $range $range_unit -timezone ${:timezone}]
			set date_in_range [clock scan $date2 -format "%Y-%m-%d" -timezone ${:timezone}]
			return [expr {$date_in_range >= $range_start &&	$date_in_range <= $range_stop}]
		}

		# ts1/ts2 MUST be ISO timestamps: YYYY-MM-DD HH:MM:SS
		:public method in_range {ts1 range range_unit ts2} {
			set range_start [clock scan $ts1 -format "%Y-%m-%d %H:%M:%S" -timezone ${:timezone}]
			set range_stop [clock add $range_start $range $range_unit -timezone ${:timezone}]
			set timestamp_in_range [clock scan $ts2 -format "%Y-%m-%d %H:%M:%S" -timezone ${:timezone}]
			return [expr {$timestamp_in_range >= $range_start && $timestamp_in_range <= $range_stop}]
		}
		################################################### NEED TO BE CHECKED ###################################################


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
				set init_date [: ISO_timestamp]
			}
			return [clock format [clock add [clock scan $init_date -format "%Y-%m-%d %H:%M:%S"] $action$val $val_type] -format "%Y-%m-%d %H:%M:%S" -timezone "${:timezone}"]
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
			if {$db_timestamp eq "" || $db_timestamp eq "null"} {
				return ""
			}
			# Remove timezone offset or Z if present
			#regsub {(\.\d+)?(Z|[+-][0-9]{2}:[0-9]{2})$} $db_timestamp "" clean_timestamp
			regsub {(\.\d+)?(Z|[+-][0-9]{2}(:[0-9]{2})?)?$} $db_timestamp "" clean_timestamp

			if {[string match "*T*" $clean_timestamp]} {
				set fmt "%Y-%m-%dT%H:%M:%S"
			} else {
				set fmt "%Y-%m-%d %H:%M:%S"
			}
			set epochTime [clock scan $clean_timestamp -format $fmt -timezone "UTC"]
			return [clock format $epochTime -format "%Y-%m-%d %H:%M:%S" -timezone "${:timezone}"]
		}
	}
}
