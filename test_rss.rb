require 'rss'
require 'open-uri'

#feed  = RSS::Parser.parse( 'http://code.google.com/feeds/p/vardbdev/issueupdates/basic')
#feed  = RSS::Parser.parse('http://groups.google.com/group/vardb-devel/feed/atom_v1_0_msgs.xml')
#feed  = RSS::Parser.parse('http://groups.google.com/group/vardb-devel/feed/rss_v2_0_msgs.xml')
feed  = RSS::Parser.parse('http://groups.google.com/group/vardb-devel/feed')
puts "<h1>" + feed.title.content + "</h1>"
n = 0
feed.items.each do |item|
	break if n == 5
	puts "<h3>" + item.title.content + "</h3>"
	puts item.content.content
	puts "<a href=" + item.link.href + ">View more...</a>"
	puts
	n += 1
end
