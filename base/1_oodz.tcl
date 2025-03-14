# Main OODZ Superclass (What is my purpose? To keep server name, path and hardcoded address https:// + $name_server) 
namespace eval oodz {
	nx::Class create superClass {
	 	:property -accessor public {oodz_version "0.0.1"}
	 	:property -accessor public {srv:substdefault {[ns_info server]}}
	 	:property -accessor public {srvpath:substdefault {[ns_pagepath]}}
	 	:property -accessor public {srvaddress:substdefault {https://[ns_info server]}}
	}

	# Simple singleton class to write separate log file
	nx::Class create log -superclass superClass {
		:variable instance:object

		:public object method create {args} {
			return [expr {[info exists :instance] ? ${:instance} : [set :instance [next]]}]
		}

		:method init {} {
			set oodz_log_dir [file join [ns_info home] logs]
			set logfile [file join $oodz_log_dir ${:srv}.oodz.log]
			set :oodzlog [ns_asynclogfile open "$logfile"]
		}
		
		:public method notice {args} {
			: write [lindex $args 0] Notice 
			# Put to system log too
			ns_log Notice [lindex $args 0]
		}
		
		:public method warning {args} {
			: write [lindex $args 0] Warning 
			# Put to system log too
			ns_log Warning [lindex $args 0]
		}

		:public method error {args} {
			: write [lindex $args 0] Error
			# Put to system log too
			ns_log Error [lindex $args 0]
		}

		:public method fatal {args} {
			: write [lindex $args 0] Fatal
			# Put to system log too
			ns_log Fatal [lindex $args 0]
		}
		
		:public method bug {args} {
			: write [lindex $args 0] Bug
			# Put to system log too
			ns_log Bug [lindex $args 0]
		}
		
		:public method debug {args} {
			: write [lindex $args 0] Debug
			# Put to system log too
			ns_log Debug [lindex $args 0]
		}
		
		:public method dev {args} {
			: write [lindex $args 0] Dev
			# Put to system log too
			ns_log Dev [lindex $args 0]
		}
		
		:method write {args} {
			ns_asynclogfile write ${:oodzlog} "\[[ns_fmttime [ns_time] "%d/%b/%Y %a %T"]\] | [lindex $args 1]: | [lindex $args 0] \n"
		}
		
		:create ::oodzLog
	}
}