#!/usr/bin/env perl
#
# SeqMiner is a tool for mining sequence information. It aims to
# help detect sequences belonging to specific protein families.
#
# Author::    Diego Diez  (mailto:diego10ruiz@gmail.com)
# Copyright:: Copyright (c) 2010
# License::   Distributes under the same terms as Ruby
# Comment::   This is the only Perl file in the project- performance.

use strict;
use warnings;

my $file = $ARGV[0];
if (! -e $file ) {
	print STDERR "* file does not exists- no duplicates found!\n";
	exit;
}

my $a;
{
	local $/=undef;
	open IN, $file;
	binmode IN;
	$a = <IN>;
	close IN;
}

my %a; # accepted entries.
my %d; # discarded entries.
my %check; # to store versions and check for changes.
my %gi; # to store GI.
my @L;
my @a = split("LOCUS", $a); # split into entries.
#print STDERR "* original file length: ".scalar @a." entries\n";
shift @a;
#my $n = 0;
#print STDERR "* original file length: ".scalar @a." entries\n";
#for my $a (@a) {
#	print "LOCUS$a";
#	exit if $n > 2;
#	$n++;
#}
#print @a;
#print STDERR "* entries printed: $n\n";
#exit;
for my $entry (@a) {
	$entry = "LOCUS".$entry;
	$entry =~ /LOCUS\s+(.+?) /;
	my $l = $1;
	#print STDERR "$l\n";

	$entry =~ /VERSION\s+(.+?) /;
	my $v = $1;
	
	$entry =~ /GI:(.+)/;
	my $gi = $1;

	if (! exists($check{$l})) {
		$check{$l} = $v;
		$gi{$l} = $gi;
		$a{$l} = $entry;
		push @L, $l;
	} else {
		my $v1 = $check{$l};
		$v1 =~ s/.+\.//;

		my $v2 = $v;
		$v2 =~ s/.+\.//;
		print STDERR "* detected duplicated entries:\n";
		print STDERR "\t$l\t$check{$l}\t$gi{$l}\n";
		print STDERR "\t$l\t$v\t$gi\n";
#		print STDERR "\t$v1\t$v2\n";
		if ($v2 > $v1) {
			print STDERR "* using $v as the new seq.\n";
			# set new accepted/discarded.
			$d{$gi{$l}} = $a{$l};
			$a{$l} = $entry;
			# update current version.
			$check{$l} = $v;
			$gi{$l} = $gi;
			
		}
	}
}

my $l = scalar keys %d;
print STDERR "* duplicates: $l\n";
if($l > 0) {
	# move file to backup:
	print STDERR "* making backup of original file ($file) ... \n";
	my $outfile = $file."_ori";
	system "mv -v $file $outfile";
	
	# print discarded.
	$outfile = $file."_discarded";
	unlink $outfile;
	print STDERR "* creating file with duplicates ($outfile) ... \n";
	open OUT, ">$outfile";
	for my $e (keys %d) {
#		print STDERR " - writting $e\n";
		print OUT $d{$e};
		#print OUT "\/\/";
	}
	close OUT;

	# print accepted.
	$outfile = $file;
	unlink $outfile;
	print STDERR "* creating file with accepted entries ($outfile) ... \n";
	open OUT, ">$outfile";
	#for my $e (keys %a) {
	for my $e (@L) {
#		print STDERR " - writting $e\n";
		print OUT $a{$e};
		#print OUT "\/\/";
	}
	close OUT;
}