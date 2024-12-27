namespace eval oodz {
	# Define the fileClass class
	nx::Class create fileClass {
		# Class variables (properties)
		:property {fileName ""}
		:property {fileExtension ""}
		:property {fileSize -1}
		:property {hfileSize ""}
		
		# Constructor method
		:method init {} {
			if {${:fileName} eq ""} {
				set :fileName [::fileutil::tempfile]
			}
			:fileExtension
		}

		# Method to read from a file
		:public method readFile {} {
			try {
				set fileHandle [open ${:fileName} r]
				set fileContent [read $fileHandle]
				close $fileHandle
				set code ok
				set msg $fileContent
			} on error {emsg} {
				oodzLog error "Can't read file: ${:fileName} - $emsg"
				set code error
				set msg $emsg
			} finally {
				return -code $code $msg
			}
		}

		# Method to write data to a file with a specified open mode (e.g., 'w' for write, 'a' for append)
		:public method writeFile {data openMode} {
			try {
				set fileHandle [open ${:fileName} $openMode]
				puts $fileHandle $data
				close $fileHandle
				set code ok
				set msg "Data written to file ${:fileName} in mode $openMode"
			} on error {emsg} {
				oodzLog error "Can't write to file: ${:fileName} in mode $openMode - $emsg"
				set code error
				set msg $emsg
			} finally {
				return -code $code $msg
			}
		}
		
		# Method to copy a file to a new location, if file exists it will be overwritten
		:public method copyFile {newPath} {
			try {
				if {[file isdirectory $newPath] == 1} {
					set newPath [file join $newPath [file tail [:fileName]]]
				}
				file copy -force ${:fileName} $newPath
				set code ok
				set msg "File copied to $newPath"
			} on error {emsg} {
				oodzLog error "Can't copy file: ${:fileName} to $newPath - $emsg"
				set code error
				set msg $emsg
			} finally {
				return -code $code $msg
			}
		}

		# Method to delete a file
		:public method deleteFile {} {
			try {
				file delete -force ${:fileName}
				set code ok
				set msg "File ${:fileName} deleted"
			} on error {emsg} {
				oodzLog error "Cant delete file: ${:fileName} - $emsg "
				set code error
				set msg $emsg
			} finally {
				return -code $code $msg
			}
		}
		
		# Method to move a file
		:public method moveFile {newPath} {
			try {
				if {[file isdirectory $newPath] == 1} {
					set newPath [file join $newPath [file tail [:fileName]]]
				}
				file rename -force ${:fileName} $newPath
				set :fileName $newPath
				:fileExtension
				set code ok
				set msg "File moved to $newPath"
			} on error {emsg} {
				oodzLog error "Can't move file: ${:fileName} to $newPath - $emsg"
				set code error
				set msg $emsg
			} finally {
				return -code $code $msg
			}
		}

		# Method to get file size
		:public method fileSize {} {
			try {
				set :fileSize [file size ${:fileName}]
				set :hfileSize [::hrfilesize::bytestohr ${:fileSize}]
				set code ok
				set msg "${:hfileSize}"
			} on error {emsg} {
				set :fileSize -1
				oodzLog error "Can't get file size of: ${:fileName} - $emsg"
				set code error
				set msg $emsg
			} finally {
				return -code $code $msg
			}
		}
		
		:public method fileName {} {
			return ${:fileName}
		}

		# Additional methods as needed...
		:public method fileExtension {} {
			if {[:isFile] == 1} {
				set :fileExtension [file extension ${:fileName}]
			}
			return ${:fileExtension}
		}
		
		:public method isFile {args} {
			return [file isfile ${:fileName}]
		}
		
		:public method isDirectory {args} {
			return [file isdirectory ${:fileName}]
		}
		
		:public method exists {args} {
			return [file exists ${:fileName}]
		}
	}
}