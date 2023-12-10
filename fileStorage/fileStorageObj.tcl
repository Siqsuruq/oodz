namespace eval oodz {
	nx::Class create fileStorageObj -superclasses {baseObj fileObj} {
		:property {ext ""}
		:property {original_name ""}
		
		:method init {} {
			set :user_data_dir [file join [::oodzConf get path] [::oodzConf get_global user_data_dir]]
			next
			if {[: is_empty] == 1} {
				:add [dict create original_name ${:fileName}]
			}
		}
		
		:public method addToFileStorage {} {
			# Logic to insert a new file record into the database
			:add [dict create ext [: getFileExtension]]
			:add [dict create path ${:fileName}]
			:add [dict create uuid_user [::oodzSession get uuid_user]]
			return [:save2db]
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
		
	}
}