# namespace eval oodz {
# 	nx::Class create fileStorageObj -superclasses {baseObj fileClass} {
# 		:property {user_data_dir:substdefault {[file join [::oodzConf get path] [::oodzConf get_global user_data_dir]]}}
# 		:property {original_name ""}
		
# 		:method init {} {
# 			next
# 			if {[: is_empty] == 1} {
# 				:add [dict create original_name ${:fileName}]
# 			} else {
# 				:updateObj
# 			}
# 		}
		
# 		:method updateObj {} {
# 			set :fileName [:get data original_name L]
# 		}
		
# 		:public method load_data {args} {
# 			next
# 			:updateObj
# 		}

# 		:public method load_default {args} {
# 			next
# 			:updateObj
# 		}
		
# 		:public method addToFileStorage {} {
# 			# Logic to insert a new file record into the database
# 			:add [dict create ext [: getFileExtension]]
# 			:add [dict create path ${:fileName}]
# 			:add [dict create uuid_user [::oodzSession get uuid_user]]
# 			return [:save2db]
# 		}
		
# 		:public method fileCategory {} {
# 			set res uknown
# 			set data_types [dict create image [list .jpg .jpeg .png .gif .tiff .svg .bmp .raw] docs [list .pdf .txt .doc .docx .odt .xls .xlsx .ods .ppt .pptx]\
# 			video [list .mp4 .mpg .mpeg .mpv .webm .ogg .avi .mov .wmv] audio [list .mp3 .wav .aiff .aac .wma] application [list .exe .bat .sh] qrcode [list .qr]\
# 			arquive [list .zip .rar .7z] digisign [list .sig .pem]]
# 			dict for {type f_exts} $data_types {
# 				if {[lsearch -nocase $f_exts ${:fileExtension}] != -1} {
# 					set res $type
# 				}
# 			}
# 			return $res
# 		}
		
# 	}
# }