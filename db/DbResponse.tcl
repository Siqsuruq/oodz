namespace eval oodz {
	nx::Class create DbResponse -superclass superClass {
		:property status:required
		:property data:required
		:property details
	}
}