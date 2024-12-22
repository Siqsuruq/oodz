namespace eval oodz {
    nx::Class create sdataClass -superclass baseClass {
        :property {sid ""}
        #:variable instances:dict
        set :instances [dict create]
        :variable instance:object


        # Class method to create or return a singleton instance for a given session ID
        :public method create {args} {
            # Get the session ID
            set sessionId [::oodzSession id]
            set instanceName "${sessionId}.sdata"
            puts "Creating sdata instance $sessionId"

            if {[info exists :instance]} {
                set :instance ${:instance}
            } else {
                set :instance [next]
           }
        }

        :method init {args} {
            set :sid [::oodzSession id]
            puts "Initializing sdata ${:sid}"
        }

        :public method clear_sdata {} {
            puts "clear_sdata  ${:sid}"
        }

        :public method get_sdata {} {
            puts "get_sdata  ${:sid}"
        }
    }
}
