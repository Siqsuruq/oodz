namespace eval tPackage {
	nx::Class create tPackageMetadata {
		:method init {} {
			puts "Metadata"
		}
	}

	nx::Class create tPackage {
		:method init {} {
			puts "Package"
		}
	}
}
