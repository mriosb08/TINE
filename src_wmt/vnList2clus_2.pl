#!/usr/bin/perl

use strict;
if($#ARGV != 0){
	print "USAGE: ./vnList2clus.pl <list>\n";
	exit(0);
}
my $file = $ARGV[0];
open(LIST, "<$file") or die "could not open file $file\n";
my %vnclasses = ();

while(my $line = <LIST>){
	if($line !~ m/^#/){
		chomp($line);
		my @classes = split(/\s+/,$line);
		my $verb = shift(@classes);
		my $allClass = join(' ',@classes);		
		$vnclasses{$allClass} .= $verb." ";
		
	}	
}
close(LIST);
open(OUT, ">vnClus_2.txt") or die "could not create file\n";
print OUT "# vnclass verb1 verb2 ...\n";
foreach my $key(keys(%vnclasses)){
	print OUT "$key $vnclasses{$key}\n";
}
close(LIST);
