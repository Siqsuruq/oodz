# Server Side Events
namespace eval oodz {
	nx::Class create sse -superclass baseClass {
		:method init {} {
		}
		
		:public method handle_request {} {
			set :channel [ns_connchan detach]
			ns_connchan write ${:channel} [append _ \
										"HTTP/1.1 200 OK\r\n" \
										"Cache-Control: no-cache\r\n" \
										"X-Accel-Buffering': no\r\n" \
										"Content-type: text/event-stream\r\n" \
										"\r\n"]
			ns_connchan write ${:channel} "data: Hi There!\n\n"
			ns_connchan write ${:channel} "data: Start time is: [clock format [clock seconds]]\n\n"
		}
		
		:public method answer {args} {
			: handle_request
		}
	}
}

::oodz::sse create ::oodzSSE
ns_register_proc GET /sse [list ::oodzSSE answer]