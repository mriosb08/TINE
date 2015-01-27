#!/usr/bin/perl
use simsDB;

my $sims = new simsDB(threshold=>200);
$word_a = 'dog';
$word_b = 'cat';
$sims->setWords($word_a,$word_b);
$in = $sims->getIntersection();

print "Related\n" if($in == 1);
my @x = $sims->getWords($ARGV[0]);
print "@x\n";
