#!/usr/bin/perl
#use perl -Ireader reader_example.pl
if($#ARGV != 0){
	print "use: perl -Ireader reader_example.pl <conll-file> > <output>\n";
	exit(0);
}
use strict;

use ColumnReader;

my $input = $ARGV[0];

my $columnReader = new ColumnReader(file => $input, trim => 1); #input file
my %columns;

my $i = 0;

while ($columnReader->readNext(\%columns)){ #reads sentences until the end of the files
								# retunrs the sentence in a hash
	print "<sentence $i>\n";	
	foreach my $col(sort keys(%columns)){
		#do something for each sorted column
		print "<feature>$columns{$col}</feature>\n";
	}
	print "</sentence $i>\n";
	$i++;
}
