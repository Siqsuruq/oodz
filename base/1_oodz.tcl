# Main OODZ Superclass (What is my purpose? To keep server name, path and hardcoded address https:// + $name_server) 
namespace eval oodz {
	nx::Class create superClass {
		:property {version "0.0.1"}
		:property {srv:substdefault {[ns_info server]}}
		:property {path:substdefault {[ns_pagepath]}}
		:property {srvaddress:substdefault {https://[ns_info server]}}
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
			puts [lindex $args 0]
		}
		
		:public method warning {args} {
			: write [lindex $args 0] Warning 
		}

		:public method error {args} {
			: write [lindex $args 0] Error
			# Put to system log too
			puts [lindex $args 0]

		}

		:public method fatal {args} {
			: write [lindex $args 0] Fatal 
		}
		
		:public method bug {args} {
			: write [lindex $args 0] Bug 
		}
		
		:public method debug {args} {
			: write [lindex $args 0] Debug 
		}
		
		:public method dev {args} {
			: write [lindex $args 0] Dev 
		}
		
		:method write {args} {
			ns_asynclogfile write ${:oodzlog} "\[[ns_fmttime [ns_time] "%d/%b/%Y %a %T"]\] | [lindex $args 1]: | [lindex $args 0] \n"
		}
	}
}