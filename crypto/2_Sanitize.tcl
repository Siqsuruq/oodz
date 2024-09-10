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
		
		:public object method normalize_spaces_dict {datadict} {
			if {[dict is_dict $datadict] != 0} {
				set result [dict create]
				dict for {dkey val} $datadict {
					dict set result $dkey [string trim [regsub -all {[\s]+} $val " "]]
				}
				return $result
				
			} else {
				return []:normalize_spaces $datadict]
			}
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
