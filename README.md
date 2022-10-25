---
## What is "OODZ"?

"OODZ" is a simple collection of NX (Next-Scripting Framework https://next-scripting.org/xowiki/) object oriented classes for developing the RestFull APIs and Web Applications using Tcl and Naviserver.
It is still a work in progress :)

---
## How to install "OODZ"

"OODZ" is a simple Tcl module for Naviserver, it is basically a folder in the global tcl library on Naviserver.
To install it just clone repo to global tcl library folder.
For example,lets assume that Naviserver installed in /opt/ns, and global tcl library folder is /opt/ns/tcl. Run this inside /opt/ns/tcl
>> git clone https://maksym_zinchenko@bitbucket.org/maksym_zinchenko/oodz.git

---
## OODZ Init Config

# Modules to load
ns_section			"ns/server/${server}/modules" {
	ns_param		oodz				tcl
}

ns_section			"ns/server/${server}/module/oodz" {
	ns_param		oodz					Tcl
	ns_param		oodz_log_dir			${homedir}/logs
	ns_param		ssl						1
	ns_param		api_version				"v2"
}