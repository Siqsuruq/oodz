nx::Class create httpClientClass -superclass ::oodz::baseClass {
    :property {baseUrl ""}
    :property {timeout 5000}
    :property {lastResponse ""}
    :property {lastRequest ""}
    :property {headers ""}
    :property {req_method ""}
    :property {body ""}
    :property {strict true}

    
    :method init {} {
        next
    }

    ### Public Requests Methods ###
    :public method postReq {args} {
        set path [lindex $args 0]
        if {[lindex $args 1] ne ""} {
            : setBody [lindex $args 1]
        }
        set :req_method "POST"
        :runReq $path
    }

    :public method getReq {args} {
        set path [lindex $args 0]
        set queryParams [lindex $args 1]  ;# optional
        set :req_method "GET"
        :runReq $path $queryParams
    }

    :public method putReq {args} {
        set path [lindex $args 0]
        if {[lindex $args 1] ne ""} {
            : setBody [lindex $args 1]
        }
        set :req_method "PUT"
        :runReq $path
    }

    :public method deleteReq {args} {
        set path [lindex $args 0]
        set queryParams [lindex $args 1]  ;# optional
        set :req_method "DELETE"
        :runReq $path $queryParams
    }

    :public method addHeader {newHeaders} { 
        dict for {key value} $newHeaders {
            dict set :headers $key $value
        }
    }

    :method getHeaders {} {
        set s [ns_set create]
        dict for {key value} ${:headers} {
            ns_set put $s $key $value
        }
        return $s
    }

    :method runReq {path {queryParams ""}} {
        set url [:buildURL $path]
        set headers [:getHeaders]
        # Prepare ns_http run options
        set opts [list -method ${:req_method} -timeout ${:timeout} -headers $headers]
        if {${:req_method} in {"POST" "PUT"} && ${:body} ne ""} {
            lappend opts -body ${:body}
        }
        try {
            set :lastRequest [list method ${:req_method} url $url headers ${:headers} body ${:body}]
            # Construct the final argument list
            set result [ns_http run {*}$opts $url]
            :parseResponse $result
        } on error {errMsg} {
            return -code error "Error in HTTP request: $errMsg"
        } finally {
            if {${:req_method} in {"POST" "PUT"}} {
                set :body ""
            }
        }
    }

    :public method setBody {value} {
        set :body $value
    }

    :public method setUrlEncodedBody {dictData} {
        set encodedList {}
        dict for {key value} $dictData {
            lappend encodedList "[ns_urlencode -part query $key]=[ns_urlencode -part query $value]"
        }
        set :body [join $encodedList "&"]
    }

    :method encodeQueryParams {queryParams} {
        set encodedList {}
        dict for {key value} $queryParams {
            lappend encodedList "[ns_urlencode -part query $key]=[ns_urlencode -part query $value]"
        }
        return [join $encodedList "&"]
    }


    :method buildURL {path {queryParams ""}} {
        if {${:baseUrl} eq ""} {
            set fullUrl $path
        } else {
            set fullUrl [ns_absoluteurl $path ${:baseUrl}]
        }
        if {$queryParams ne ""} {
            append fullUrl "?" [:encodeQueryParams $queryParams]
        }
        return $fullUrl
    }

    :method parseResponse {response} {
        try {
            set status [dict get $response status]
            set body [dict get $response body]
            set headers [ns_set array [dict get $response headers]]
            set contentType [string tolower [dict getnull $headers "content-type"]]
            set parsedBody ""
            if {[string match "application/json*" $contentType]} {
                if {[catch {set parsedBody [json::json2dict $body]} errMsg]} {
                    ns_log warning "Failed to parse JSON body: $errMsg"
                }
            }
            set :lastResponse [dict create status $status body $body headers $headers parsedBody $parsedBody]
            if {${:strict} && $status >= 400} {
                return -code error "HTTP error $status: $body"
            }
            return -code ok [dict create status $status body $body headers $headers parsedBody $parsedBody]
        } on error {errMsg} {
            return -code error "Error in parsing response: $errMsg"
        }
    }

    :public method getLastResponse {} {
        return ${:lastResponse}
    }

    :public method getLastRequest {} {
        return ${:lastRequest}
    }
}