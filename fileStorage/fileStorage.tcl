namespace eval oodz {
	nx::Class create fileStorage -superclass baseClass {
		:property {obj "filestorage"}
		
		:method init {} {
		}
		
		:public method uploadFile {} {
			set fs_uuids [dict create]
			try {
				foreach uploaded_file [ns_conn files] {
					set f_name [ns_querygetall $uploaded_file]
					if {[catch {set mimeType [mimext get_mime [file extension $f_name]]}]} {
						set user_data_dir [file join [::oodzConf get_global user_data_dir] "unknown"]
						set full_path_user_data_dir [file join [ns_pagepath] $user_data_dir]
					} else {
						set user_data_dir [file join [::oodzConf get_global user_data_dir] $mimeType]
						set full_path_user_data_dir [file join [ns_pagepath] $user_data_dir]
					}
					if {$f_name ne ""} {
						set tmp_file [ns_getformfile $uploaded_file]
						set f [::oodz::fileObj create f -fileName $tmp_file]

						set oodz_tempfile "[::oodz::Crypto generate_random 20][file extension $f_name]"
						$f moveFile [file join $full_path_user_data_dir $oodz_tempfile]

						set fs_uuid [::db insert_all filestorage [dict create path [file join $user_data_dir $oodz_tempfile] ext [file extension $f_name] original_name $f_name uuid_user [::oodzSession get uuid_user]] "" uuid_filestorage]
						dict set fs_uuids $uploaded_file $fs_uuid
						$f destroy
					}
				}
				return -code ok $fs_uuids
			} on error {errMsg} {
				oodzLog error "Error in uploadFile method: $errMsg"
				return -code error $errMsg
			}
		}
		
		# Return relative filePath from DB by uuid_filestorage
		:public method getFilesPath {args} {
			set result ""
			foreach fileuuid $args {
				set fpath [dict getnull [lindex [::db select_all filestorage path uuid_filestorage=\'$fileuuid\'] 0] path]
				if {$fpath ne ""} {
					lappend result $fpath
				}
			}
			return $result
		}
		
		# Return full filePath from DB by uuid_filestorage
		:public method getFullFilesPath {args} {
			set result ""
			foreach fileuuid $args {
				set fpath [dict getnull [lindex [::db select_all filestorage path uuid_filestorage=\'$fileuuid\'] 0] path]
				if {$fpath ne ""} {
					lappend result [file join [::oodzConf get path L] $fpath]
				}
			}
			return $result
		}
		
		:public method getFileURL {args} {
			set result ""
			foreach fileuuid $args {
				set fpath [dict getnull [lindex [::db select_all filestorage path uuid_filestorage=\'$fileuuid\'] 0] path]
				if {$fpath ne ""} {
					lappend result [file join [::oodzConf get srvaddress L] $fpath]
				}
			}
			return $result
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
					return [::oodz::fileObj new -fileName $fpath]
				} else {
					return -code error "File not found"
				}
			} on error {errMsg} {
				oodzLog error "Error in getFileById method: $errMsg"
				return -code error $errMsg
			}
		}
	}
}