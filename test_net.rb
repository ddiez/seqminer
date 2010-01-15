require 'net/http'

Net::HTTP.start('www.plasmodb.org') do |http|
	resp = http.get('/common/downloads/release-6.3/Pfalciparum/Pfalciparum_PlasmoDB-6.3.gff')
	f = File.open("foo.gff", "wb")
	f.write(resp.body)
	f.close
end
