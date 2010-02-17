require 'rss'
require 'open-uri'

# This is Atom.
#feed = RSS::Parser.parse( 'http://code.google.com/feeds/p/vardbdev/issueupdates/basic')

# Requires the Feed to be public! (unless I can find a way around).
#feed = RSS::Parser.parse('http://groups.google.com/group/vardb-devel/feed/atom_v1_0_msgs.xml')
#feed = RSS::Parser.parse('http://groups.google.com/group/vardb-devel/feed/rss_v2_0_msgs.xml')

feed = RSS::Parser.parse('http://groups.google.com/group/vardb-test/feed/rss_v2_0_msgs.xml')
#feed = RSS::Parser.parse('http://groups.google.com/group/vardb-test/feed/atom_v1_0_msgs.xml')

# For RSS.
puts "<h1>" + feed.channel.title + "</h1>"
n = 0
feed.items.each do |item|
	break if n == 5
	puts "<h3>" + item.title + "</h3>"
	puts item.description
	puts "<a href=" + item.link + ">View more...</a>"
	puts
	n += 1
end

# For Atom.
# This is not working for google groups: item.content is nil!.
# It does work for google code.
#puts "<h1>" + feed.title.content + "</h1>"
#n = 0
#feed.items.each do |item|
#	break if n == 5
#	puts "<h3>" + item.title.content + "</h3>"
#	puts item.content.content
#	puts "<a href=" + item.link.href + ">View more...</a>"
#	puts
#	n += 1
#end
