nx::Class create hCaptchaClass -superclass ::oodz::baseClass {
    :method init {} {
		next
	}

    :public method verify_hcaptcha {responseToken} {
        if {$responseToken eq ""} {
            return -code error "Captcha is not solved. Response token is empty."
        }
        set :httpClientObj [httpClientClass new -baseUrl "https://hcaptcha.com"]
        try {
            # Step 1: Set Content-Type header
            ${:httpClientObj} addHeader [dict create "Content-Type" "application/x-www-form-urlencoded"]
            # Step 2: Prepare URL-encoded body
            ${:httpClientObj} setUrlEncodedBody [dict create secret "$::env(HCAPTCHA_SECRET)" response $responseToken]
            # Step 3: Make the request
            set response [${:httpClientObj} postReq "/siteverify"]
            set parsedBody [dict get $response parsedBody]
            # Step 4: Check the response
            if {[dict getnull $parsedBody success] eq "true"} {
                return -code ok 1
            } else {
                return -code ok 0
            }
        } on error {errMsg} {
            return -code error "Error in HTTP request: $errMsg"
        } finally {
            ${:httpClientObj} destroy
        }
    }
}