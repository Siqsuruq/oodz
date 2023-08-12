# Generic object Sanitize
namespace eval oodz {
	nx::Object create Sanitize {
		:public object method remove_tags {str} {
			set pattern {<.*?>}
			regsub -all $pattern $str "" result
			return $result 
		}

		:public object method unquotehtml {html} {
			return [string map {&amp; & &gt; > &lt; < &quot; \" &#34; \" &#39; ' &#123; \{ &#125; \}} $html]
		}

		:public object method quotehtml {html} {
			return [string map {& &amp; > &gt; < &lt; \" &#34; ' &#39; \{ &#123; \} &#125;} $html]
		}
		
		:public object method normalize_spaces {originalString {type "str"}} {
			if {$type eq "str"} {
				return [string trim [regsub -all {[\s]+} $originalString " "]]
			} elseif {$type eq "dict"} {
				set result [dict create]
				dict for {dkey val} $originalString {
					dict set result $dkey [string trim [regsub -all {[\s]+} $val " "]]
				}
				return $result
			}
		}
		:public object method normalize_list_spaces {listString} {
			set normalizedList [list]
			foreach element $listString {
				lappend normalizedList [string trim [regsub -all {[\s]+} $element " "]]
			}
			return $normalizedList
		}
		
		:public object method normalize_spaces {data} {
			set normalizedData [list]
			foreach item $data {
				lappend normalizedData [string trim [regsub -all {[\s]+} $item " "]]
			}
			# If only one string was provided (i.e., not a list), just return the single string
			if {[llength $data] == 1} {
				return [lindex $normalizedData 0]
			}
			return $normalizedData
		}


	}
}
