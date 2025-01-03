namespace eval oodz {
	nx::Class create fileStorage -superclass ::oodz::baseObj {
		:property {obj "filestorage"}
		:property {user_data_dir:substdefault {[file join [::oodzConf get path L] [::oodzConf get_global user_data_dir]]}}

		:method init {} {
			next
		}

		:method getMimeDiscreteType {file} {
			try {
				set ext [file extension $file]
				set mime [::mimext get_mime $ext]
				set discrete_type [::mimext get_discrete_type $mime]
				return -code ok $discrete_type
			} on error {errMsg} {
				oodzLog error "Error in getMimeType method: $errMsg"
				return -code ok "unknown"
			}
		}

		:public method uploadFile {} {
			set fs_uuids [dict create]
			try {
				set result ""
				puts "UPLOADING FILE ---------------------------"
				foreach uploaded_file [ns_conn files] {
					puts "Uploaded file: $uploaded_file"
					set original_fname [ns_querygetall $uploaded_file]
					puts "File name: $original_fname"
					set file_ext [file extension $original_fname]

					set discrete_type [:getMimeDiscreteType $original_fname]
					set fs_dir [file join ${:user_data_dir} $discrete_type]	
					if {$original_fname ne ""} {
						set tmp_file [ns_getformfile $uploaded_file]
						set f [::oodz::fileClass new -fileName $tmp_file]
						set fs_filename [::uuid::uuid generate]${file_ext}
						$f moveFile [file join $fs_dir $fs_filename]
						$f destroy
						
						:add [dict create path [file join $discrete_type $fs_filename] ext $file_ext original_name $original_fname dz_user [::oodzSession get uuid_daidze_user]]
						set res [:save2db]
						lappend result [lindex $res 0]
					}
				}
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
					set fpath [dict getnull [lindex [::db select_all filestorage path uuid_filestorage=\'$fileuuid\'] 0] path]
					if {$fpath ne ""} {
						lappend result $fpath
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
					set fpath [dict getnull [lindex [::db select_all filestorage path uuid_filestorage=\'$fileuuid\'] 0] path]
					if {$fpath ne ""} {
						lappend result [file join ${:user_data_dir} $fpath]
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
					set fpath [dict getnull [lindex [::db select_all filestorage path uuid_filestorage=\'$fileuuid\'] 0] path]
					if {$fpath ne ""} {
						lappend result [ns_absoluteurl [file join [::oodzConf get_global user_data_dir] $fpath] [::oodzConf get srvaddress L]]
						# lappend result [file join "[::oodzConf get srvaddress L]" [::oodzConf get_global user_data_dir] $fpath]
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