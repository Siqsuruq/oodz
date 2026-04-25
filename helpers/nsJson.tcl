# Requires Naviserver >= 5.1.0 for JSON support
namespace eval ::oodz {
    nx::Class create nsJson {
        :method init {} {
            set :json ""
        }
    }
}