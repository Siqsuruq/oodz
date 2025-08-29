namespace eval oodz {
	nx::Class create fileStorage -superclass ::oodz::baseObj {
		:property {obj "filestorage"}
		:property {user_data_dir:substdefault {[file join [::oodzConf get srvpath L] [::oodzConf get_global user_data_dir]]}}

		:method init {} {
			package require mimext
			next
		}

		:method getMimeDiscreteType {file} {
			try {
				set mimeString [ns_guesstype $file]
				set ix [string first / $mimeString]
				if {$ix >= 0} {
					incr ix -1
					set discrete_type [string range $mimeString 0 $ix]
				} else {
					return -code error "Invalid MIME type: $mimeString"
				}
				if {$discrete_type eq "multipart" || $discrete_type eq "message"} {
					set discrete_type "multipart"
				}
				return -code ok $discrete_type
			} on error {errMsg} {
				oodzLog error "Error in getMimeType method: $errMsg"
				return -code ok "unknown"
			}
		}

		:method save_to_db {filepath ext original_name} {
			set qb [InsertSQLBuilder new -tableName filestorage]
			try {
				$qb addRow [dict create filepath $filepath ext $ext original_name $original_name dz_user [::oodzSession get uuid_daidze_user]]
				$qb setReturningColumns uuid_filestorage
				set res [::db execute_query [$qb buildQuery]]
				return -code ok [dict getnull [lindex $res 0] uuid_filestorage]
			} on error {errMsg} {
				oodzLog error "Error in save_to_db method: $errMsg"
				return -code error $errMsg
			} finally {
				$qb destroy
			}
		}


		# Upload files to server, result must be a dictionary with uploaded field name as key and uuid_filestorage as value
		:public method uploadFile {} {
			set fs_uuids [dict create]
			try {
				set result [dict create]
				puts "UPLOADING FILE ---------------------------"
				foreach uploaded_file [ns_conn files] {
					set original_fname [ns_querygetall $uploaded_file]
					set file_ext [file extension $original_fname]
					set discrete_type [:getMimeDiscreteType $original_fname]
					set fs_dir [file join ${:user_data_dir} $discrete_type]	
					# if {![file isdirectory $fs_dir]} {
					# 	file mkdir $fs_dir
					# }
					if {$original_fname ne ""} {
						set tmp_file [ns_getformfile $uploaded_file]
						set f [::oodz::fileClass new -fileName $tmp_file]
						set fs_filename [::uuid::uuid generate]${file_ext}
						$f moveFile [file join $fs_dir $fs_filename]
						$f destroy
						set res [: save_to_db [file join $discrete_type $fs_filename] $file_ext $original_fname]
						dict set result $uploaded_file [lindex $res 0]
					}
				}
				puts "File saved to DB: $result"
				return -code ok $result
			} on error {errMsg} {
				oodzLog error "Error in uploadFile method: $errMsg"
				return -code error $errMsg
			}
		}
		
		# Return relative filePath from DB by uuid_filestorage
		:public method getFilesPath {args} {
			try {
				set result ""
				foreach fileuuid $args {
					if {$fileuuid eq ""} {
						continue
					} else {
						set fpath [dict getnull [lindex [::db select_all filestorage filepath uuid_filestorage=\'$fileuuid\'] 0] filepath]
						if {$fpath ne ""} {
							lappend result $fpath
						}
					}
				}	
				return $result
			} on error {errMsg} {
				oodzLog error "Error in getFilesPath method: $errMsg"
				return -code error $errMsg
			}
		}
		
		# Return full filePath from DB by uuid_filestorage
		:public method getFullFilesPath {args} {
			try {
				set result ""
				foreach fileuuid $args {
					if {$fileuuid eq ""} {
						continue
					} else {
						set fpath [dict getnull [lindex [::db select_all filestorage filepath uuid_filestorage=\'$fileuuid\'] 0] filepath]
						if {$fpath ne ""} {
							lappend result [file join ${:user_data_dir} $fpath]
						}
					}
				}
				return $result	
			} on error {errMsg} {
				oodzLog error "Error in getFullFilesPath method: $errMsg"
				return -code error $errMsg
			}
		}
		
		:public method getFileURL {args} {
			try {
				set result ""
				foreach fileuuid $args {
					puts "Getting file URL for uuid: $fileuuid"
					if {$fileuuid eq "" || $fileuuid eq "{}"} {
						continue
					} else {
						set fpath [dict getnull [lindex [::db select_all filestorage filepath uuid_filestorage=\'$fileuuid\'] 0] filepath]
						if {$fpath ne ""} {
							lappend result [ns_absoluteurl [file join [::oodzConf get_global user_data_dir] $fpath] [::oodzConf get srvaddress L]]
							# lappend result [file join "[::oodzConf get srvaddress L]" [::oodzConf get_global user_data_dir] $fpath]
						}
					}
				}
				return $result	
			} on error {errMsg} {
				oodzLog error "Error in getFileURL method: $errMsg"
				return -code error $errMsg
			}
		}

		:public method deleteFile {args} {
			try {
				foreach fileuuid $args {
					set fpath [:getFullFilesPath $fileuuid]
					if {$fpath ne ""} {
						file delete -force $fpath
						::db delete_rows filestorage $fileuuid
					}
				}
				return -code ok "File deleted"
			} on error {errMsg} {
				oodzLog error "Error in deleteFile method: $errMsg"
				return -code error $errMsg
			}
		}

		:public method getFileById {fileuuid} {
			try {
				set fpath [:getFullFilesPath $fileuuid]
				if {$fpath ne ""} {
					return [::oodz::fileClass new -fileName $fpath]
				} else {
					return -code error "File not found"
				}
			} on error {errMsg} {
				oodzLog error "Error in getFileById method: $errMsg"
				return -code error $errMsg
			}
		}

		:public method save2db {args} {
			:remove [list ts]
			next
		}
	}
}