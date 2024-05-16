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

		:public object method verify_file_signature {fileToCheck fileHash fileSign pubKeyPEMStr} {
			set pubKey [new_CkPublicKey]
			set rsa [new_CkRsa]
			set bdHash [new_CkBinData]
			set bdSig [new_CkBinData]
			
			try {
				set success [CkPublicKey_LoadFromString $pubKey $pubKeyPEMStr]
				if {$success == 0} then {
					puts [CkPublicKey_lastErrorText $pubKey]
				} else {puts "PEM loaded"}
				
				set success [CkRsa_ImportPublicKeyObj $rsa $pubKey]
				if {$success == 0} then {
					puts [CkRsa_lastErrorText $rsa]
				}
				set success [CkBinData_LoadFile $bdHash $fileHash]
				if {$success == 0} then {
					puts "Failed to load SHA256 hash. $fileHash"
				} else {puts "SHA256 loaded."}
				set success [CkBinData_LoadFile $bdSig $fileSign]
				if {$success == 0} then {
					puts "Failed to load RSA signature."
				} else {puts "Signature loaded."}
				set enc "base64"
				CkRsa_put_EncodingMode $rsa $enc
				set success [CkRsa_VerifyHashENC $rsa [CkBinData_getEncoded $bdHash $enc] "sha256" [CkBinData_getEncoded $bdSig $enc]]
				if {$success == 0} then {
					puts [CkRsa_lastErrorText $rsa]
					puts "Not Valid"
				} else {puts "Signature validated."}
			} finally {
				delete_CkPublicKey $pubKey
				delete_CkRsa $rsa
				delete_CkBinData $bdHash
				delete_CkBinData $bdSig
			}
		}
		
		:public object method hash_file {file_path {algorithm "sha256"}} {
			try {
			# Select the hashing algorithm
				switch $algorithm {
					"sha256" {
						set hash [::sha2::sha256 -bin -file $file_path]
						set extension "sha256"
					}
					"md5" {
						set hash [::md5::md5 -file $file_path]
						set extension "md5"
					}
					default {
						set hash [::sha2::sha256 -bin -file $file_path]
						set extension "sha256"
					}
				}
				# Compute the SHA-256 hash of the file and save it to the file with .sha256 extension
				set output_file "${file_path}.${extension}"
				set file_handle [open $output_file "wb"]
				puts $file_handle $hash
				return -code ok $output_file
			} on error {errMsg} {
				return -code error "Error occurred: $errMsg"
			} finally {
				# Ensure file handle is closed in case of an error during writing
				if {[info exists file_handle]} {
					close $file_handle
				}
			}
		}
	}
}