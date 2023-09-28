namespace eval oodz {
	nx::Object create Crypto {
		### General methods, common use:
		:public object method generate_random {{length 15} {digits 1} {lowercase 1} {uppercase 1}} {
			set fortuna [new_CkPrng]
			set key [CkPrng_randomString $fortuna $length $digits $lowercase $uppercase]
			delete_CkPrng $fortuna
			return $key
		}

		:public object method random_password {{length 8} {digits 1} {mixed 1} {other 1} {exclude 0} {simple 1}} {
			set fortuna [new_CkPrng]
			if {$length < 6} { set length 6}
			# The generated password must contain one of the following non-alphanumeric chars (other).
			if {$other == 1 && $simple == 1} {
				set other ".,!?_"	
			} elseif {$other == 1 && $simple != 1} {
				set other "!\"£$%^&*()_+-={};':@#~<>,.?/\\|"
			} else {
				set other ""
			}
			# Exclude chars that appear similar to others:
			if {$exclude == 1} {
				set excludeChars "iIlLoO0"
			} else {
				set excludeChars ""
			}
			set password [CkPrng_randomPassword $fortuna $length $digits $mixed $other $excludeChars]
			delete_CkPrng $fortuna
			return $password
		}
		
		:public object method random_string {{length 10}} {
			return [:generate_random $length 0 1 1]
		}
		
		:public object method random_num {{length 10}} {
			return [:generate_random $length 1 0 0]
		}
		
		### Key Generation, Derivation:
		# 256 bits = 32 bytes, encodings: hex, base64url, base64, or binary
		:public object method generate_key {{length 32}} {
			return [ns_crypto::randombytes -encoding base64 $length]
		}

		:public object method generate_random_salt {{salt_length 16}} {
			return [ns_crypto::randombytes -encoding base64 $salt_length]
		}

		:public object method derive_key {password} {
			if {$password ne ""} {
				set salt [:generate_random_salt]  ;# Generate a random salt
				set iterations 50000
				set dklen 32  ;# 256 bits = 32 bytes
				set digest "sha256"
				set key [ns_crypto::pbkdf2_hmac -digest $digest -dklen $dklen -iterations $iterations -salt $salt -secret $password -encoding base64]
				return [join [list $salt $key] "."]
			} else {
				error "Empty password provided!"
			}
		}




	}
}