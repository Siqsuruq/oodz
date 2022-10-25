nx::Class create Cli {
  #
  # We overload the system method "create". In the modified method we
  # save the created instance in the instance variable named
  # "instance"
  #
  :property obj1:object

	:public method print {} {
		return [${:obj1} get data]
	}
}

::oodz_baseclass create dzu -data "id 1 name max"
::oodz_baseclass create dzu2