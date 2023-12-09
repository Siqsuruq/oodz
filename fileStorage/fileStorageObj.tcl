namespace eval oodz {
	nx::Class create fileStorageObj -superclasses baseObj -mixins fileObj {
		:property {uuid_filestorage ""}
		:property {ext ""}
		
		:method init {} {
			next
			: add [dict create ext [:getFileExtension]]
		}
	}
}