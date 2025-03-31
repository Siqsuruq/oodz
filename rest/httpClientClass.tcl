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
        set :body [lindex $args 1]  ;# optional
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
        set :body [lindex $args 1]  ;# optional
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
            set headers [dict get $response headers]
            set :lastResponse $response
            if {${:strict} && $status >= 400} {
                return -code error "HTTP error $status: $body"
            }
            return -code ok [dict create status $status body $body headers $headers]
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