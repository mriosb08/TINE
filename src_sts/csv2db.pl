#!/usr/bin/perl
use strict;
#use Text::CSV;
use BerkeleyDB;
use Scalar::Util qw(looks_like_number);

if($#ARGV != 1){
	print "usage:./csv2db <csv-file> <db-name>\n";
	print "input format lhs<tab>rhs<tab>score\n";
	exit 1;
}

my ($file, $dbname) = (shift, shift);



#my $csv = Text::CSV->new(sep_char => "\t");
my $db1 = new BerkeleyDB::Btree(-Filename => "$dbname\.db",-Flags =>DB_CREATE,-Property  => DB_DUP)or die "ERROR: $BerkeleyDB::Error\n";
open (my $CSV, "<", $file) or die "file not found\n";
my $i = 0;
while (my $line=<$CSV>) {	
	chomp($line);
	#print "$line\n";	
	my($lhs, $rhs, $score)  = split(/\t/, $line);
	my $key = $lhs.'|||'.$rhs;
	if(looks_like_number($score)){
		$db1->db_put($key,$score);
	}
   	

}
close $CSV;
