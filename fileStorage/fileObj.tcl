namespace eval oodz {
	# Define the fileObj class
	nx::Class create fileObj {
		# Class variables (properties)
		:property fileName:required
		:property {fileExtension ""}
		:property {fileSize -1}
		:property {hfileSize ""}
		
		# Constructor method
		:method init {} {
			:getFileExtension
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
				file rename -force ${:fileName} $newPath
				set :fileName $newPath
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

		# Additional methods as needed...
		:public method getFileExtension {} {
			if {![:isFile]} {
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