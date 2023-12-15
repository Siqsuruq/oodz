namespace eval oodz {
	nx::Class create fileStorage -superclass baseClass {
		:property {identifier ""}
		:property obj:required
		:property {db:object,required}
		
		:method init {} {
			set :user_data_dir [file join [::oodzConf get path] [::oodzConf get_global user_data_dir]]
		}
		
		:public method uploadFile {} {
			set save_ids [dict create]
			foreach upl_file [ns_conn files] {
				set f_name [ns_querygetall $upl_file]
				if {$f_name ne ""} {
					set tmp_file [ns_getformfile $upl_file]
					::oodz::fileStorageObj create fso -db ::db -obj filestorage -fileName ""
					
					set type [: ftype $f_name]
					set fext [file extension $f_name]
					set path [file join ${:user_data_dir} $type]
					: check_user_data_dir $path
					::fileutil::tempdir $path
							
					set savefile [::fileutil::tempfile]
					file copy -force  -- $tmp_file $savefile

					::fileutil::tempdirReset
					file rename -force -- $savefile $savefile$fext
					set full_fname [file tail $savefile]$fext
					dict set save_ids $upl_file [${:db} insert_all filestorage [dict create path [file join $type $full_fname] ext $fext original_name $f_name uuid_user [::oodzSession get uuid_user]] "" id]
				}
			}
			return $save_ids
		}
		
		# Return relative filePath from DB by fileuuid
		:public method getFilesPath {args} {
			set result ""
			foreach fileuuid $args {
				set fpath [dict getnull [lindex [${:db} select_all filestorage path uuid_filestorage=\'$fileuuid\'] 0] path]
				if {$fpath ne ""} {
					lappend result [file join [::oodzConf get_global user_data_dir] $fpath]
				}
			}
			return $result
		}
		
		# Return full filePath from DB by fileuuid
		:public method getFullFilesPath {args} {
			set result ""
			foreach fileuuid $args {
				set fpath [dict getnull [lindex [${:db} select_all filestorage path uuid_filestorage=\'$fileuuid\'] 0] path]
				if {$fpath ne ""} {
					lappend result [file join ${:user_data_dir} $fpath]
				}
			}
			return $result
		}
		
		:public method getFilesAPIUrl {args} {
			set result ""
			foreach fileuuid $args {
				lappend result [ns_absoluteurl $fileuuid [::oodzConf get srvaddress]/api/v1/filestorage/]
			}
			return $result
		}
		
		# Helper Methods
		:method check_user_data_dir {path} {
			if {[file exists $path] == 0 } {
				file mkdir $path
			} elseif {[file exists $path] != 0 && [file isdirectory $path] ==0} {
				file mkdir $path
			}
		}
		
		:public method ftype {f_name} {
			set res uknown
			set data_types [dict create image [list .jpg .jpeg .png .gif .tiff .svg .bmp .raw] docs [list .pdf .txt .doc .docx .odt .xls .xlsx .ods .ppt .pptx]\
			video [list .mp4 .mpg .mpeg .mpv .webm .ogg .avi .mov .wmv] audio [list .mp3 .wav .aiff .aac .wma] application [list .exe .bat .sh] qrcode [list .qr]]
			set mfext [file extension $f_name]
			dict for {type f_exts} $data_types {
				if {[lsearch -nocase $f_exts $mfext] != -1} {
					set res $type
				}
			}
			return $res
		}
		
		proc list_files {dir_name {file_ext ""}} {
			set result ""
			if {[llength $file_ext] ne 0} {
				foreach ext $file_ext {
					set f_l [glob -nocomplain -dir $dir_name *$ext]
					if {[llength $f_l] != 0} {
						foreach f $f_l {
							lappend result [file tail $f]
						}
					}	
				}
			} else {
				set f_l [glob -nocomplain -dir $dir_name *]
				if {[llength $f_l] != 0} {
					foreach f $f_l {
						lappend result [file tail $f]
					}
				}
			}
			return [lsort -dictionary $result]
		}

		:public method create_dir {dir_name} {
			set result 0
			try {
				set new_dir [string map {"../" ""} $dir_name]
				file mkdir [file join ${:user_data_dir} $new_dir]
				puts "DIRECTORY TO MAKE: [file join ${:user_data_dir} $new_dir] USER DATA DIR: ${:user_data_dir} NEW DIR $new_dir"
				set result 1
			} trap {} {arr} {
				oodzLog error "Create directory ERROR: $arr"
			} finally {
				return $result
			}
		}

		proc deldir {dir_name} {
			if {[file exists $dir_name] != 0} {
				file delete -force $dir_name
			}
		}

		proc dz_filewrite {filename data {mode w}} {
			if [catch {set fd [open $filename $mode]} errmsg] {
				ns_log notice "File write error: $errmsg"
				close $fd
			} else {
				fconfigure $fd
				puts -nonewline $fd $data
				close $fd
			}
		}

		proc dz_fileread {filename} {
			if {[file exists $filename]} { 
				set fd [open $filename]
				fconfigure $fd -translation binary
				set data [read $fd]
				close $fd
				return $data
			} else {return ""}
		}

		proc dz_txt_fileread {filename} {
			if {[file exists $filename]} { 
				set fd [open $filename]
				set data [read $fd]
				close $fd
				return $data
			} else {return ""}
		}

		proc dz_filecreate {filename} {
			set fd [open $filename a+]
			close $fd
		}

		:public method dz_temp {ext} {
			set path [file join [set ${srv}::path] [set ${srv}::tmp_dir]]
			set dz_tmp "[ns_mktemp $path/dz-XXXXXX]$ext"
			return $dz_tmp
		}
		
	
	}
}