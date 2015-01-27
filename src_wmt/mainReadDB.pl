#!/usr/bin/perl

use strict;

use readDB;
if($#ARGV != 1){
	print "USAGE: ./mainReadDB.pl <dbName> <query>\n";
	exit(0);
}

my $dbname = $ARGV[0];
my $db = readDB->new(dbname=>$dbname);
my $query = $ARGV[1];

my $data = $db->getData($query);

my ($relation,$weight)=split(/\s+/,$data);
print "QUERY:$query RELATION:$relation WEIGHT:$weight\n";

