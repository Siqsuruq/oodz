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

		:public object method generate_apikey {} {
			set prefix "[:generate_random 7]."
			set uuid [ns_uuid]
			set api_keyb64 [ns_base64encode $uuid]
			set api_key "$prefix$api_keyb64"
			return $api_key
		}

		:public object method verify_file_signature {fileToCheck fileSign pubKeyPEM} {
			set pubKey [new_CkPublicKey]
			set rsa [new_CkRsa]
			set enc "hex"
			CkRsa_put_EncodingMode $rsa $enc

			# Create a CkCrypt2 object for hashing and set the algorithm to SHA256.
			set crypt [new_CkCrypt2]
			CkCrypt2_put_HashAlgorithm $crypt "sha256"
			set hashBytes [new_CkByteData]
			set bdSig [new_CkByteData]
			
			try {
				# Load Public key PEM string
				if {[CkPublicKey_LoadFromString $pubKey $pubKeyPEM] == 0} {
					::oodzLog error "Error loading public key from string: [CkPublicKey_lastErrorText $pubKey]"
					return -code error "Error loading public key from string."
				}
				if {[CkRsa_ImportPublicKeyObj $rsa $pubKey] == 0} {
					::oodzLog error "Error importing public key: [CkRsa_lastErrorText $rsa]"
					return -code error "Error importing public key."
				}
		
				# Hash the file contents using SHA256
        		if {[CkCrypt2_HashFile $crypt $fileToCheck $hashBytes] == 0} {
					::oodzLog error "Error hashing original file: [CkCrypt2_lastErrorText $crypt]"
					return -code error "Error hashing original file"
				}
				
				# Load the signature file
				if {[CkByteData_loadFile $bdSig ${fileSign}] == 0} {
					::oodzLog error "Error loading signature file: [CkByteData_lastErrorText $bdSig]"
					return -code error "Error loading signature file."
				}

				# Verify the hash against the signature
				if {[CkRsa_VerifyHash $rsa $hashBytes "sha256" $bdSig] == 0} {
					::oodzLog error "Signature not valid: [CkRsa_lastErrorText $rsa]"
					return -code error "Signature not valid."
				} else {
					return -code ok "Signature is valid."
				}
			} on error {errMsg} {
				return -code error "Error occurred: $errMsg"
			} finally {
				delete_CkPublicKey $pubKey
				delete_CkRsa $rsa
				delete_CkCrypt2 $crypt
				delete_CkByteData $hashBytes
				delete_CkByteData $bdSig
			}
		}
		
		:public object method write_hash_file {file_path {algorithm "sha256"} {enc "binary"}} {
			try {
				set hash [:hash_file $file_path $algorithm $enc]
				set extension [string tolower $algorithm]
				set output_file "${file_path}.${extension}"
				set file_handle [open $output_file "wb"]
				puts $file_handle $hash
				return -code ok $output_file
			} on error {errMsg} {
				return -code error "Error in method write_hash_file: $errMsg"
			} finally {
				# Ensure file handle is closed in case of an error during writing
				if {[info exists file_handle]} {
					close $file_handle
				}
			}
		}
	
		:public object method hash_file {file_path {algorithm "sha256"} {enc "binary"}} {
			try {
				# Select the hashing algorithm
				switch $algorithm {
					"sha256" {
						set hash [ns_md file -digest sha256 -encoding ${enc} $file_path]
					}
					"sha512" {
						set hash [ns_md file -digest sha512 -encoding ${enc} $file_path]
					}
					"sha3-256" {
						set hash [ns_md file -digest "sha3-256" -encoding ${enc} $file_path]
					}
					"sha3-512" {
						set hash [ns_md file -digest "sha3-512" -encoding ${enc} $file_path]
					}
					"md5" {
						set hash [ns_md file -digest "md5" -encoding ${enc} $file_path]
					}
					default {
						set hash [ns_md file -digest sha256 -encoding ${enc} $file_path]
					}
				}
				return -code ok $hash
			} on error {errMsg} {
				return -code error "Error in method hash_file: $errMsg"
			}
		}

		:public object method hash_password {password} {
			set salt [:generate_random_salt]
			set hash [::ns_crypto::scrypt -secret "$password" -salt "$salt" -n 1024 -r 8 -p 16]
			return [join [list $salt $hash] "."]
		}

		:public object method verify_hash_password {password hash} {
			set salt [lindex [split $hash "."] 0]
			set hash [lindex [split $hash "."] 1]
			set newHash [::ns_crypto::scrypt -secret "$password" -salt "$salt" -n 1024 -r 8 -p 16]
			return [expr {$newHash eq $hash}]
		}
	}
}