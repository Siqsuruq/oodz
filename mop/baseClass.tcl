namespace eval oodz {
	nx::Class create baseClass -superclass superClass {
		:method init {} {
		
		}
	################################################################
		# Object data manipulation methods
		
		# Public interface to add or modify values in an object, need dicttool package
		# Accepts only one argument, type dict, key value pairs to add or if key exists replace value
		:public method add {args} {
			set a [lindex $args 0]
			if {$a ne "" && [dict is_dict $a] == 1} {
				# set :obj_data [dict merge ${:obj_data} $a]
				dict for {key value} $a {
					:object property {${key} ${value}}  
				}
			}
		}
	}
}