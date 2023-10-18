
namespace eval ::oodz {
    nx::Class create CollectionClass -superclasses ::nx::Class

    CollectionClass create ICollection {
        :property {name "DefaultCollection"}
		
        # ... other properties

        
        # ... other methods for the collection interface
    }

    CollectionClass create IndexedCollection -superclasses ICollection {
		:variable objects [dict create]
        :public method add {key value} {
            # Method to add key-value pair to the collection
			dict append :objects $key $value
        }
        
        :public method get {key} {
            # ... method to get value by key from the collection
        }
        
		# Method to get the count of elements in the collection
        :public method length {} {
			return [dict size ${:objects}]
		}
		
		# Method to clear collection
		:public method clear {} {
			set :objects [dict create]
		}
    }

    CollectionClass create NonIndexedCollection -superclasses ICollection {
		:variable objects [list]
		:variable currentIdx -1
		
		# Method to add element to the collection
        :public method add {value} {
			lappend :objects $value
        }
        
		# Method to get a single element at a specific index or to return the entire collection when no index is provided
        :public method get {{index ""}} {
			if {$index eq ""} {
				return [lindex ${:objects}]
			} elseif {$index >= 0 && $index < [:length]} {
				return [lindex ${:objects} $index]
			} else {
				oodzLog warning "Invalid Index"
				return ""
			}
        }
		
		# Iteration Methods for iterating over the elements in the collection, which allow you to perform actions on each element.
		:public method moveNext {} {
			incr :currentIdx
			if {${:currentIdx} < [:length]} {
				return 1
			} else {
				return 0
			}
		}

		:public method reset {} {
			set :currentIdx -1
		}

		:public method current {} {
			if {${:currentIdx} >= 0 && ${:currentIdx} < [:length]} {
				return [:get ${:currentIdx}]
			} else {
				error "Invalid index"
			}
		}
		
		# Method to get the count of elements in the collection
		:public method length {} {
			return [llength ${:objects}]
		}
		
		# Method to clear collection
		:public method clear {} {
			set :objects [list]
		}
		
		:public method remove {index} {
			if {$index < 0 || $index >= [:length]} {
				oodzLog warning "Invalid Index"
				return -1 ;# Indicate an error
			}

			set removedValue [lindex ${:objects} $index]
			set :objects [lreplace ${:objects} $index $index]

			if {$index < ${:currentIdx}} {
				incr :currentIdx -1
			}

			return $removedValue
		}

    }

    nx::Class create CollectionFactory {
        :public method createCollection {-collection_type:class,type=CollectionClass} {
            return [$collection_type new]
        }
        :create ::collectionFactory
    }
}