require 'bio'

f = Bio::GFF::GFF3.new(File.open('foo.gff'))

s = f.sequences
S = {}
s.each do |seq|
	seq.na
	S[seq.entry_id] = seq
end

def _parse_gene_attributes(c)
	id = nil
	desc = ""
	pseudo = 0
	f = {}
	c.each do |val|
		f[val[0]] = val[1]
	end
	id = f["ID"]
	desc = f["description"]
	pseudo = 1 if desc.match("pseudogene")
	[id, desc, pseudo]
end


f.records.each do |record|
	if record.feature == "gene"
		chr = record.seqname
		(id, desc, pseudo) = _parse_gene_attributes(record.attributes)
		if ! S[chr].nil?
			foo = S[chr].subseq(record.start, record.end)
			puts foo.to_fasta(id, 60)
		else
			puts "**** gene " + id + " NOT FOUND!!!" if ! found
		end
		exit if id.match(/MAL13P1\.107/)
	end
end