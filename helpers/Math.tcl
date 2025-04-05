namespace eval oodz {
    ::nx::Object create mathObj {
        # Checks if number is whole and returns integer, if not will trim nonsignificant zeros from right and return result
        :public object method return_significant { float } {
            set a [expr abs($float - int($float)) > 0 ? 0 : 1]
            if {$a == 1} {
                return [expr int($float)]
            } else {
                return [string trimright $float 0]
            }
        }
    }
}