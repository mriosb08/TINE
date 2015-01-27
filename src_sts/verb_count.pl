#!/usr/bin/perl
use strict;
if($#ARGV != 0){
	print "verb_count.pl <score-file>\n";
	exit 1;
}

my $file = shift;

open(my $FILE, "<", $file) or die "file not found\n";
my $zp = 0;
my $zn = 0;
my $seg_p = 0;
my $seg_n = 0;
my $total = 0;
while(my $line = <$FILE>){
	chomp($line);
	my($a, $b, $pair, $ent, $tine, $f, $a, $score) = split(/\s+/, $line);
	if($a == 0 and $ent == 0){
		$zn++;
	}elsif($a == 0 and $ent == 1){
		$zp++;
	}
	if($ent == 0){
		$seg_n++;
	}elsif($ent == 1){
		$seg_p++;
	}
	$total++;
}

print "coverage for sem metric over true:". ($seg_p - $zp). " out of: $seg_p\n";
print "coverage for sem metric over false:". ($seg_n - $zn). " out of: $seg_n\n";
print "total: $total\n";
