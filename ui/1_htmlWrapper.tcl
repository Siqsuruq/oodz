namespace eval oodz {
	nx::Class create htmlWrapper {
		:property {conf:object,required}
		:property {frame "main"}
		:property module:required
		:property xmlFile:required

		:method init {} {
			set xml_file [file join [ns_pagepath] [${:conf} get_global mod_dir] ${:module} ${:xmlFile} ]
			ns_adp_puts "File to wrap: $xml_file"
			set doc [dom parse [tdom::xmlReadFile $xml_file]]
			set hd "[$doc asXML]"
			::htmlparse::parse -cmd [list [self] html_wrapper] $hd
		}
		
		
		:public method html_wrapper {args} {
			foreach a $args {
				lappend ar_l [string trim $a]
			}
			set tag [lindex $ar_l 0]
			set tagsgn [lindex $ar_l 1]
			set props [lindex $ar_l 2]
			set val [lindex $ar_l 3]
			set a [lindex $ar_l 4]	
			
			# ns_adp_puts "Some tag: $tag <br>"
			################################################# FORM ################################################# 
			if {$tag eq "form"} {
				if {$tagsgn eq "/"} {
					ns_adp_puts  "</form><br>"
				} else {
					set pr_dict [: props_2_dict $props $tag $val]
					dict with pr_dict {}
					if {[dict exists $pr_dict var]} {set id [dict get $pr_dict var]} else {set id ${:frame}}
					if {[dict exists $pr_dict autocomplete] != 0 && [dict get $pr_dict autocomplete] eq "off"} {
						ns_adp_puts "<form method=\"post\" id=\"$id\" action=\"/process_form\" enctype=\"multipart/form-data\" autocomplete=\"off\">"
					} else {
						ns_adp_puts "<form method=\"post\" id=\"$id\" action=\"/process_form\" enctype=\"multipart/form-data\">"
					}

				}
			################################################# LINE ################################################# 
			} elseif {$tag eq "line"} {
				if {$tagsgn eq "/"} {
				} else {
					ns_adp_puts "<hr>"
				}
			################################################# CONTAINER ################################################# 
			} elseif {$tag eq "container"} {
				if {$tagsgn eq "/"} {
					ns_adp_puts "</div>\n"
				} else {
					set pr_dict [: props_2_dict $props $tag $val]
					dict with pr_dict {}

					if {[dict get $pr_dict type] eq "frame" && [dict get $pr_dict pos] eq "hor"} {
						ns_adp_puts "<div class=\"row\">"
					} elseif {[dict get $pr_dict type] eq "frame" && [dict get $pr_dict pos] eq "ver"} {
						# Bootstrap Auto-layout columns
						ns_adp_puts "<div class=\"col\">"
					}
				}
			################################################# ACCORDION ################################################# 
			} elseif {$tag eq "accordion"} {
				if {$tagsgn eq "/"} {
					ns_adp_puts "</div></div></div></div><br>"
					# : dev_comments $tag
				} else {
					# : dev_comments $tag start
					set pr_dict [: props_2_dict $props $tag $val]
					dict with pr_dict {}
					ns_adp_puts "<div class=\"$class\" id=\"accordion_$var\">"
					ns_adp_puts "<div class=\"accordion-item\">"
					
					ns_adp_puts "<h2 class=\"accordion-header\" id=\"heading_$var\">"
					ns_adp_puts "<button class=\"accordion-button\" type=\"button\" data-bs-toggle=\"collapse\" data-bs-target=\"#$var\" aria-expanded=\"true\" aria-controls=\"$var\">"
					ns_adp_puts "[::msgcat::mc $label]"
					ns_adp_puts "</button>"
					ns_adp_puts "</h2>"

					ns_adp_puts "<div id=\"$var\" class=\"accordion-collapse collapse $collapse\" aria-labelledby=\"heading_$var\" data-bs-parent=\"#accordion_$var\">"
					ns_adp_puts "<div class=\"accordion-body\">"				
				}
			################################################# LABEL ################################################# 
			} elseif {$tag eq "label"} {
				if {$tagsgn eq "/"} {
					ns_adp_puts  "</h3></div></div>\n"
				} else {
					set pr_dict [: props_2_dict $props $tag $val]
					dict with pr_dict {}
					ns_adp_puts "<div class=\"row\"><div class=\"col\"><h3>"
					ns_adp_puts "[::msgcat::mc $val]"
				}
			} elseif {$tag eq "legend"} {
				if {$tagsgn eq "/"} {
					ns_adp_puts  "</legend></div></div><hr>\n"
				} else {
					set pr_dict [: props_2_dict $props $tag $val]
					dict with pr_dict {}
					ns_adp_puts "<div class=\"row\"><div class=\"col\"><legend>"
					ns_adp_puts "[::msgcat::mc $val]"
				}
			################################################# ENTRY || TEXT ################################################# 
			} elseif {$tag eq "entry" || $tag eq "text"} {
				if {$tagsgn eq "/"} {
					ns_adp_puts "<br>"
				} else {
					ns_adp_puts "<!-- Entry -->"
					: input $props $tag $val
					# iMask code
					if {[info exists mask] != 0 && $mask ne ""} {
						if {[dbi_0or1row {SELECT mask FROM mask WHERE name = :mask}] == 1} {
							ns_adp_puts "<script>"
							ns_adp_puts "var element = document.getElementById('$var');"
							ns_adp_puts "var maskOptions = { mask: '$mask' };"
							ns_adp_puts "var mask = IMask(element, maskOptions);"
							ns_adp_puts "</script>"
						}
					}
					ns_adp_puts "<!-- End Entry -->"
				}
			################################################# BOOL #################################################
			} elseif {$tag eq "bool"} {
				if {$tagsgn eq "/"} {
					ns_adp_puts "<br>\n"
				} else {
					set pr_dict [: props_2_dict $props $tag $val]
					dict with pr_dict {}
					set i_v [Check_sdata $var]
					if {$i_v eq "t" || $i_v == 1} {
						set ch checked
					} else {set ch ""}
				
					ns_adp_puts "<div class=\"form-check\">"
					ns_adp_puts "<input name=\"$var\" type=\"hidden\" value=\"0\">"
					ns_adp_puts "<input name=\"$var\" id=\"$var\" type=\"checkbox\" class=\"$class\" $js $ch $mandatory>"
					ns_adp_puts "<label class=\"form-check-label\" for=\"$var\">$placeholder</label>"
					ns_adp_puts "</div>"
				}
			################################################# DROPDOWN ################################################# 
			} elseif {$tag eq "dropdown"} {
				if {$tagsgn eq "/"} {
					ns_adp_puts "<br>\n"
				} else {
					set pr_dict [: props_2_dict $props $tag $val]
					dict with pr_dict {}
					set option_dict [dict create]
					
					if {[dict get $pr_dict vtype] eq "list"} {
						set values [unquotehtml [dict get $pr_dict values]]
						foreach val $values {dict append option_dict $val $val}
					} elseif {[dict get $pr_dict vtype] eq "table"} {
						set tbl [lindex [dict get $pr_dict values] 0]
						set col [lindex [dict get $pr_dict values] 1]
						set values [lsort -dictionary [select_all $tbl "$col" "none" list]]
						foreach val $values {dict append option_dict $val $val}
					} elseif {[dict get $pr_dict vtype] eq "func"} {
						set func [lindex [dict get $pr_dict values] 0]
						set values [lsort -dictionary [$func]]
						foreach val $values {dict append option_dict $val $val}
					} elseif {[dict get $pr_dict vtype] eq "func_dict"} {
						set func [lindex [dict get $pr_dict values] 0]
						set option_dict [$func]
					} elseif {[dict get $pr_dict vtype] eq "func_trns"} {
						set func [lindex [dict get $pr_dict values] 0]
						set l_2_trns [$func]
						set trns_dict ""
						foreach lval $l_2_trns {
							dict append trns_dict $lval "[::msgcat::mc $lval]"
						}
						set option_dict [lsort -dictionary -stride 2 -index 1 $trns_dict]
					} elseif {[dict get $pr_dict vtype] eq "dict"} {
						set values [unquotehtml [dict get $pr_dict values]]
						dict for {k v} $values {
							dict append option_dict $k "[::msgcat::mc "$v"]"
						}
					}
					
					set i_v [Check_sdata $var]
					ns_adp_puts "<div class=\"form-group\">"
					if {[dict exists $pr_dict but_cmd]} {
						ns_adp_puts "<div class=\"input-group\">"
						ns_adp_puts "<div class=\"input-group-prepend\">"
						ns_adp_puts "<button class=\"btn btn-outline-dark btn-sm\" type=\"button\" data-toggle=\"modal\" data-target=\"\#[dict get $pr_dict but_cmd]\">[::msgcat::mc "[dict get $pr_dict but_txt]"]</button>"
						ns_adp_puts "</div>"
					}

					ns_adp_puts "<select name=\"$var\" id=\"$var\" class=\"$class\" $js data-placeholder=\"$placeholder\" $mandatory $state>"
					ns_adp_puts "<option value=\"\" selected></option>"

					dict for {dkey dval} $option_dict {
						if {$dval eq $i_v || $dkey eq $i_v} {
							ns_adp_puts "<option value=\"$dkey\" selected>$dval</option>"
						} else {
							ns_adp_puts "<option value=\"$dkey\">$dval</option>"
						}
					}
					ns_adp_puts "</select>"
					ns_adp_puts "</div>"
					if {[dict exists $pr_dict but_cmd]} {ns_adp_puts "</div>"}
				}
			################################################# FILE ################################################# 
			} elseif {$tag eq "file"} {
				if {$tagsgn eq "/"} {
					ns_adp_puts "<br>\n"
				} else {
					set pr_dict [: props_2_dict $props $tag $val]
					dict with pr_dict {}
					
					if {[dict exists $pr_dict multiple]} {
						set multiple "multiple"
					} else {set multiple ""}
					#multiple accept="image"
					if {[dict exists $pr_dict accept]} {
						set accept "$accept"
					} else {set accept "*/*"}
						
					ns_adp_puts "<div>"
					ns_adp_puts "<input id=\"$var\" type=\"file\" class=\"$class\" data-preview-file-type=\"text\" data-show-upload=\"false\" name=\"$var\" $mandatory $state $multiple accept=\"$accept\">"
					ns_adp_puts "</div>"
				}
			################################################# BUTTON ################################################# 
			} elseif {$tag eq "button"} {
				if {$tagsgn eq "/"} {
				} else {
					: button $props $tag $val
				}
			################################################# TABLE ################################################# 
			} elseif {$tag eq "table"} {
				if {$tagsgn eq "/"} {
					ns_adp_puts "</div>"
				} else {
					set pr_dict [props_2_dict $props $tag $val]
					dict with pr_dict {}
					
					set theads_trns {}
					set theads {}
					set srv_qry_data ""
					#------------- START Table Headers
					if {[dict exists $pr_dict headers_type] != 0 && [dict get $pr_dict headers_type] == "dict"} {
						set tmp_dict [dict get $pr_dict headers]
						foreach t [dict keys $tmp_dict] u [dict values $tmp_dict] {
							lappend theads_trns [::msgcat::mc $u]
							lappend theads $t
						}
					} else {
						foreach t [dict get $pr_dict headers] {
							lappend theads_trns [::msgcat::mc $t]
							lappend theads $t
						}
					}
					#------------- STOP Table Headers
					
					
					
					
					ns_adp_puts "<br>"
					ns_adp_puts "<div class=\"table-responsive-xl\">"
					ns_adp_puts "<table name=\"$var\" id=\"$var\" class=\"table table-sm table-striped table-hover\" style=\"width:100%\">"
					
					# THEAD
					ns_adp_puts "<thead class=\"table-dark\">"
						ns_adp_puts "<tr>"
						foreach thead $theads thead_trns $theads_trns {
							ns_adp_puts "<th>$thead_trns</th>"
						}
						ns_adp_puts "</tr>"
					ns_adp_puts "</thead>"
					
					#------------- START Table Data
					#------------- STOP Table Data
					
					
					# TFOOT, show table footer if tfoot option is true
					if {[::oodz::DataType is_bool [dict getnull $pr_dict tfoot]] == 1} {
						ns_adp_puts "<tfoot>"
							ns_adp_puts "<tr>"
							foreach thead $theads thead_trns $theads_trns {
								ns_adp_puts "<th>$thead_trns</th>"
							}
							ns_adp_puts "</tr>"
						ns_adp_puts "</tfoot>"
					}
					
					ns_adp_puts "</table>"
					
					#------JScript
					ns_adp_puts "<script>"
						ns_adp_puts "\$('\#$var').DataTable( {"
							ns_adp_puts "processing: true,"
							ns_adp_puts "order: \[\[ 0, 'asc' \]\],"
							if {[::oodz::DataType is_bool [dict getnull $pr_dict select]]} { ns_adp_puts "select: 'os', blurable: true," } else { ns_adp_puts "select: false," }
							
							if {[::oodz::DataType is_bool [dict getnull $pr_dict serverSide]]} { set serverSide true } else { set serverSide false }
							if {[dict get $pr_dict type] ne "empty"} {
								ns_adp_puts "serverSide: $serverSide,"
								ns_adp_puts "ajax: '$val',"
								ns_adp_puts "type: 'POST',"
							}
							
							if {[::oodz::DataType is_bool [dict getnull $pr_dict multiSort]]} { set multiSort true } else { set multiSort false }
							ns_adp_puts "multiSort: $multiSort,"
							set a_trns [::msgcat::mc "Show all"]
							ns_adp_puts "lengthMenu: \[\[ 10, 25, 50, 100, -1 \],\[ '10', '25', '50', '100', \"$a_trns\" \]\],"
							ns_adp_puts "dom: \"<'row'<'col-sm-4'B><'col-sm-6'f><'col-sm-2'l>>tr<'row'<'col-sm-6'i><'col-sm-6'p>>\" ,"

							ns_adp_puts "buttons: \['copy', 'excel', 'pdf'\],"
							ns_adp_puts "columns: \["
								foreach thead $theads thead_trns $theads_trns {
									ns_adp_puts "{ data: '$thead' , name: '$thead_trns' },"
								}	
							ns_adp_puts "\],"
						ns_adp_puts "} );"
					ns_adp_puts "</script>"
				}
			################################################# DATE #################################################
			# NEW DATE TIME RELATED 
			} elseif {$tag eq "date" || $tag eq "time" || $tag eq "month" || $tag eq "datetime-local"} {
				if {$tagsgn eq "/"} {
					ns_adp_puts "<br>"
				} else {
					set pr_dict [: props_2_dict $props $tag $val]
					dict with pr_dict {}
					if {[dict exists $pr_dict default]} {
						set def_comm [dict get $pr_dict default]
						if {$def_comm eq "today"} {
							set def_val [date]
						} else {
							set def_val "$def_comm"
						}
					} else {
						set def_val ""
					}
					set i_v [Check_sdata $var]

					: input $props $tag $val
				}
			################################################# MODAL ################################################# 
			} elseif {$tag eq "modal"} {
				if {$tagsgn eq "/"} {
					ns_adp_puts "<!-- END MODAL -->\n"
				} else {
					set pr_dict [: props_2_dict $props $tag $val]
					dict with pr_dict {}
					ns_adp_puts "<!-- START MODAL -->\n"
					ns_adp_puts "<div class=\"modal fade\" id=\"$var\" data-bs-backdrop=\"static\" data-bs-keyboard=\"false\" tabindex=\"-1\" aria-labelledby=\"$var\" aria-hidden=\"true\">"

					ns_adp_puts "<div class=\"modal-dialog modal-dialog-centered\">"
					ns_adp_puts "<div class=\"modal-content\">"
					ns_adp_puts "<div class=\"modal-header\">"
					ns_adp_puts "<h5 class=\"modal-title fs-5\" id=\"$var\">[::msgcat::mc $val]</h5>"
					ns_adp_puts "<button type=\"button\" class=\"btn-close\" data-bs-dismiss=\"modal\" aria-label=\"[::msgcat::mc Close]\"></button>"
					
					ns_adp_puts "</div>"
					ns_adp_puts "<div class=\"modal-body\">"
						  
					set module [lindex [dict get $pr_dict values] 0]
					set xml [lindex [dict get $pr_dict values] 1]
					set xml_file [file join [ns_pagepath] [${:conf} get_global mod_dir] $module $xml]
					set doc [dom parse [tdom::xmlReadFile $xml_file]]
					set hd "[$doc asXML]"
					::htmlparse::parse -cmd [list [self] html_wrapper] $hd

					ns_adp_puts "</div>"
					ns_adp_puts "</div>"
					ns_adp_puts "</div>"
					ns_adp_puts "</div>"
				}
			}
		}
		
		:method input {props tag val} {
			set pr_dict [: props_2_dict $props $tag $val]
			dict with pr_dict {}
			set i_v [Check_sdata $var]
			if {$i_v eq "" && $value ne ""} {
				set i_v $value
			}
			
			if {$tag eq "date" || $tag eq "time" || $tag eq "month" || $tag eq "datetime-local"} { set type $tag }

			if {$tag eq "text"} {
				ns_adp_puts "<div class=\"[: def_class group]\">"
				ns_adp_puts "<textarea id=\"$var\" class=\"$class\" placeholder=\"$placeholder\" name=\"$var\" rows=\"$rows\" $mandatory>$i_v</textarea>"
				ns_adp_puts "</div>"
			} else {
				if {[dict exists $pr_dict but_cmd]} {
					ns_adp_puts "<div class=\"[: def_class group]\">"
						ns_adp_puts "<input type=\"$type\" id=\"$var\" name=\"$var\" class=\"$class\" placeholder=\"$placeholder\" aria-describedby=\"addon_$var\" value=\"$i_v\" pattern=\"\[^\\x22\]+\" $mandatory $state $js>"
						ns_adp_puts "<button id=\"addon_$var\" class=\"[: def_class button]\" type=\"button\" data-bs-toggle=\"modal\" data-bs-target=\"\#[dict get $pr_dict but_cmd]\">[::msgcat::mc "[dict get $pr_dict but_txt]"]</button>"
					ns_adp_puts "</div>"
				} elseif {[dict exists $pr_dict group]} {
					ns_adp_puts "<div class=\"[: def_class group]\">"
					ns_adp_puts "<span class=\"input-group-text\" id=\"addon_$var\">$placeholder</span>"
					ns_adp_puts "<input type=\"$type\" id=\"$var\" name=\"$var\" class=\"$class\" aria-describedby=\"addon_$var\" value=\"$i_v\" pattern=\"\[^\\x22\]+\" $mandatory $state $js>"
					ns_adp_puts "</div>"
				} else {
					ns_adp_puts "<input id=\"$var\" name=\"$var\" type=\"$type\" class=\"$class\" placeholder=\"$placeholder\" value=\"$i_v\" pattern=\"\[^\\x22\]+\" $mandatory $state $js>"
				}
			}
		}
		
		:method button {props tag val} {
			set pr_dict [: props_2_dict $props $tag $val]
			dict with pr_dict {}
			set link [list]

			# ADD IMAGE TO THE BUTTON
			if {[dict exists $pr_dict img] != 0} {
				set img_tag "<span class=\"me-2\"><img src=\"[ns_absoluteurl [dict get $pr_dict img] [oodzConf get_global icons_dir]]\"></span>"
			} else {set img_tag ""}

			if {[lindex $cmd 0] eq "\$::daidze_main"} {
				if {[lindex $cmd 1] eq "clear_values"} {
					ns_adp_puts "<button class=\"$class\" id=\"$var\" type=\"reset\" value=\"$val\" name=\"dz_name\" onclick=\"reset_all();\">$img_tag $placeholder</button>"
				} else {
					set module [lindex $cmd 2]
					if {[chk_mod_acc $module] == 1} {
						set xml [lindex $cmd 3]
						lappend link "?mod=$module&xml=$xml"
						ns_adp_puts "<a class=\"$class\" id=\"$var\" href=\"$link\" role=\"button\">$img_tag $placeholder</a>"
					}
				}
			} elseif {[lindex $cmd 0] eq "js"} {
				ns_adp_puts "<button class=\"$class\" id=\"$var\" type=\"button\" value=\"$placeholder\" name=\"dz_name\" $js>$img_tag $placeholder</button>"
			} else {
				set module [lindex [split $cmd "::"] 2]
				if {$module ne ""} {
					if {[chk_mod_acc $module] == 1} {
						ns_adp_puts "<input type=\"hidden\" value='\{[::msgcat::mc "$val"]\} $cmd' name=\"cmd\">"
						ns_adp_puts "<button class=\"$class\" id=\"$var\" type=\"submit\" value=\"$placeholder\" name=\"dz_name\">$img_tag $placeholder</button>"
					}
				} else {
					ns_adp_puts "<input type=\"hidden\" value='\{[::msgcat::mc "$val"]\} $cmd' name=\"cmd\">"
					ns_adp_puts "<button class=\"$class\" id=\"$var\" type=\"submit\" value=\"[::msgcat::mc "$val"]\" name=\"dz_name\">$img_tag $placeholder</button>"
				}
			}
		}
		
		############################################ PROP2DICT ############################################

		:method props_2_dict {props tag val} {
			set prop [string map {= { }} $props]
			
			### FOR ALL WIDGETS ###
			dict set prop placeholder [::msgcat::mc "$val"]
			
			# Props related to UI (class & Id)
			# Check class field for all widgets
			if {[dict exists $prop class] == 1} {
				set prop [dict replace $prop class [: modify_class $tag [dict getnull $prop class]]]
			} else {set prop [dict replace $prop class [: modify_class $tag]]}
			
			if {[dict exists $prop id] == 1} {
				set prop [dict replace $prop id [dict get $prop id]]
			}
			
			# Check default value
			if {[dict getnull $prop default] ne ""} {
				dict set prop value [dict getnull $prop default]
			} else {set prop [dict replace $prop value ""]}
			
			if {$tag eq "date" || $tag eq "datetime-local" && [dict exists $prop default] == 1 } {
				set res [dict getnull $prop default]
				if {$res ne "" && $res eq "today"} {
					dict set prop value [::oodzTime ISO_today]
				}
			}
			if {$tag eq "time" && [dict exists $prop default] == 1 } {
				set res [dict getnull $prop default]
				if {$res ne "" && $res eq "now"} {
					dict set prop value [::oodzTime ISO_now]
				}
			}

			# JavaScript events
			# if {[dict exists $prop js] == 1} {
				# set js_str [dict get $prop js]
				# if {[set js_args [lrange $js_str 2 end]] ne ""} {
					# set js_event "[lindex $js_str 0]=\"[lindex $js_str 1](this.form.id,this.name,this.value,'[join $js_args "','"]')\""
				# } else {
					# set js_event "[lindex $js_str 0]=\"[lindex $js_str 1](this.form.id,this.name,this.value)\""
				# }
				# set prop [dict replace $prop js $js_event]
			# } else {set prop [dict replace $prop js ""]}


			# NEW JS TEST
			if {[dict exists $prop js] == 1} {
				set js [::htmlparse::mapEscapes [dict get $prop js]]
				set js_event [dict get $js event]
				set js_functions [dict get $js func]
				set js_params [dict get $js param]
				set js_form [dict getnull $js form]
				if {$js_form ne ""} {
					set form "\['[join $js_form "','"]'\],\[this.id\],\[this.name\],\[this.value\],"
				} else {
					set form "\[this.form.id\],this.id,this.name,this.value,"
				}
				set a ""
				foreach func_name $js_functions param $js_params {
					append a [join [list $func_name "($form'[join $param "','"]');"] ""]
				}
				set prop [dict replace $prop js "$js_event=\"$a\""]
			} else {set prop [dict replace $prop js ""]}

			
			# Check var field for all widgets (set as unique id)
			if {[dict exists $prop var] == 1} {
				set prop [dict replace $prop var [dict get $prop var]]
			}

			# Check mandatory field for all widgets
			if {[dict exists $prop mandatory] == 1 && [dict get $prop mandatory] == 1} {
				set prop [dict replace $prop mandatory required]
			} else {set prop [dict replace $prop mandatory ""]}



			# Check readonly field for all widgets
			if {[dict exists $prop state] == 1 && [dict get $prop state] == "readonly"} {
			} elseif {[dict exists $prop state] == 1 && [dict get $prop state] == "disabled"} {
			} else {set prop [dict replace $prop state ""]}
			
			if {$tag eq "entry" || $tag eq "barcode"} {
				set default [dict create type "text" default ""]
				foreach key [dict keys $default] {
					if {[dict exists $prop $key] == 0} {
						dict append prop $key [dict get $default $key]
					}
				}
				if {[dict exists $prop mask] != 0} {
				set mask [dict get $prop mask]
					if {$mask eq "integer" || $mask eq "number"} {
						dict set prop type "number"
					} elseif {$mask eq "email"} {
						dict set prop type "email"
					} elseif {$mask ne ""} {
						dict set prop mask "$mask"
					}
				}
			} elseif {$tag eq "text"} {
				if {[dict exists $prop rows] != 0} { dict set prop rows [dict get $prop rows] } else { dict set prop rows 5 }
			} elseif {$tag eq "table"} {
				foreach key [dict keys $prop] {
					if {$key eq "headers"} {
						set hl [dict get $prop $key]
						dict unset prop $key
						dict append prop $key [string map {&quot; "\""} $hl]
					}
				}
			} elseif {$tag eq "btable"} {
				foreach key [dict keys $prop] {
					if {$key eq "headers"} {
						set hl [dict get $prop $key]
						dict unset prop $key
						dict append prop $key [string map {&quot; "\""} $hl]
					}
				}
			} elseif {$tag eq "dropdown"} {
				# if {[dict exists $prop search]} {
					# dict set prop search "data-live-search=\"true\" data-size=\"5\""
				# } else {dict set prop search ""}
					
				# if {[dict exists $prop onselect] != 0} {
					# set onSelect [dict get $prop onselect]
				# } else {set onSelect ""}
			} elseif {$tag eq "accordion"} {
				if {[dict exists $prop collapse] == 1 && [::oodz::DataType is_bool [dict getnull $prop collapse]] == 1} {
					set prop [dict replace $prop collapse ""]
				} else {set prop [dict replace $prop collapse "show"]}
			} elseif {$tag eq "label"} {
				if {[dict exists $prop h] == 1 && [dict get $prop h] <= 6 && [dict get $prop h] >= 1 } {
					set prop [dict replace $prop h "h[dict get $prop h]"]
				} else {set prop [dict replace $prop h ""]}
			} elseif {$tag eq "a"} {
				if {[dict exists $prop target] == 1 && [dict get $prop target] ne ""} {
					set prop [dict replace $prop target "[dict get $prop target]"]
				} else {set prop [dict replace $prop target ""]}
			}
			dict append prop sid [ns_session id]
			return $prop
		}

		:method dev_comments {args} {
			set tag [lindex $args 0]
			set position [lindex $args 1]
			if {$position eq "start"} {
				ns_adp_puts "<!-- START $tag -->"
			} else {
				ns_adp_puts "<!-- END $tag -->"
			}
		}

		:method modify_class {tag {new_class ""}} {
			set default_class [: def_class $tag]
			
			if {$new_class ne ""} {
				if {[llength $new_class] > 1} {
					set class_action [lindex $new_class 0]
					set class_name [lrange  $new_class 1 end]
					if {$class_action eq "+"} {
						return [concat $default_class $class_name]
					} elseif {$class_action eq "-"} {
						return [remove_from_list $default_class $class_name]
					} else {return $new_class}
				} else {
					return $new_class
				} 
			} else {
				return $default_class
			}
		}
		
		:method def_class {tag} {
			set def_class [dict create \
				form ""\
				line ""\
				container ""\
				accordion "accordion"\
				accordion-item ""\
				label ""\
				legend ""\
				h1 ""\
				h2 ""\
				h3 ""\
				h4 ""\
				h5 ""\
				h6 ""\
				p ""\
				a "btn btn-outline-dark btn-sm btn-block"\
				plain_html ""\
				chart ""\
				html_string ""\
				html_file ""\
				adp ""\
				article ""\
				template ""\
				section ""\
				div ""\
				banner ""\
				entry "form-control form-control-sm"\
				group "input-group input-group-sm"\
				radio "form-check-input"\
				file "file"\
				month "form-control form-control-sm"\
				datetime-local "form-control form-control-sm"\
				date "form-control form-control-sm"\
				time "form-control form-control-sm"\
				clock "form-control form-control-sm"\
				button "btn btn-outline-dark btn-sm btn-block"\
				jsbutton "btn btn-outline-dark btn-sm btn-block"\
				mod_button "btn btn-outline-dark btn-sm btn-block"\
				modal ""\
				text "form-control"\
				msg "alert alert-dark"\
				image ""\
				qrcode ""\
				image_upload ""\
				bool "form-check-input"\
				dropdown "form-control form-control-sm selectpicker"\
				geomap ""\
				spinbox "form-control"\
				editor ""\
				dz_mod ""\
				old_table "data-table table table-striped table-sm table-hover"\
				code_editor ""\
				heditor ""\
				table "btable table-sm table-striped table-hover"\
				calendar ""\
				video "video-js vjs-fluid vjs-theme-forest"\
			]
			return [dict getnull $def_class $tag]
		}
	}
}