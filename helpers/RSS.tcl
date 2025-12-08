namespace eval ::oodz {
	nx::Class create Rss {
        :property {title:required}
        :property {link:required}
        :property {description:required}
        :property {language "en-us"}
        :property {lastBuildDate ""}
        :property {items ""}

        :public method init {} {
            # Set default lastBuildDate to now in RFC822 format
            set :lastBuildDate [clock format [clock seconds] -format "%a, %d %b %Y %H:%M:%S GMT" -gmt true]
        }

        :public method add_item {title link description pubDate guid} {
            lappend :items [dict create \
                title $title \
                link $link \
                description $description \
                pubDate $pubDate \
                guid $guid]
        }

        :public method to_xml {} {
            set doc [dom createDocument rss]
            set rss [$doc documentElement]
            $rss setAttribute version "2.0"

            set channel [$rss appendChild [$doc createElement channel]]

            foreach {tag value} {
                title ${:title}
                link ${:link}
                description ${:description}
                language    ${:language}
                lastBuildDate ${:lastBuildDate}
            } {
                set el [$doc createElement $tag]
                $el appendChild [$doc createTextNode $value]
                $channel appendChild $el
            }

            foreach item ${:items} {
                set itemEl [$doc createElement item]
                foreach key {title link description pubDate guid} {
                set el [$doc createElement $key]
                $el appendChild [$doc createTextNode [dict get $item $key]]
                    $itemEl appendChild $el
            }
                $channel appendChild $itemEl
            }

            return [$doc asXML -indent 2]
        }

    }
}