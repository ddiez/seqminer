#!/usr/bin/env perl
use Bio::DB::EUtilities;

my $id = shift;
my $db = shift;
my $file = shift;
#my $special = shift;

#if ($special eq "babesia") {
	#$id = $id."+biomol genomic[properties]";
	#$db = "nuccore";
#}

print STDERR "# DOWNLOAD\n";
print STDERR "* term: $id\n";
print STDERR "* db: $db\n";
print STDERR "* file: $file\n";

#print STDERR "* downloading [$db]: $id\n";
my $factory = new Bio::DB::EUtilities (
	-eutil => 'esearch',
	-term  => $id,
	-db => $db,
	-usehistory => 'y',
	-verbose => -1
);

my $count = $factory->get_count;
print STDERR "* count: $count\n";
if ($count > 0) {
	my $hist = $factory->next_History || die 'No history data returned';
	$factory->set_parameters(
		-eutil => 'efetch',
		-rettype => 'gbwithparts',
		-history => $hist
	);

	my ($retmax, $retstart) = (500, 0);
	my $retry = 0;
	RETRIEVE_SEQS:
	while ($retstart < $count) {
		$factory->set_parameters(-retmax => $retmax,
								-retstart => $retstart);
		eval{
			my $ret = $retstart + $retmax;
			$ret = $count if $ret > $count;
			printf STDERR "\r* progress: %.1f%s [%i]",
				100 * $ret/$count, "%", $ret;
			$factory->get_Response(-file => ">>$file");
		};
		if ($@) {
			die "\nServer error: $@.  Try again later" if $retry == 10;
			print STDERR "\nServer error, redo #$retry\n";
			$retry++ && redo RETRIEVE_SEQS;
		}
		$retstart += $retmax;
	}
	print STDERR "\n";
}
