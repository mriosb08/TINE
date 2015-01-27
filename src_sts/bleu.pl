#!/usr/bin/perl

# This is just to test BLEU.pm
#
#
#

use strict;
use BLEU;


my $ref = "NP VP PP NP PP NP";
my $hyp = "NP VP PP NP NP";

my ($score, $type, $counts) = BLEU::sbleu(ref => $ref, hyp => $hyp, fallback => 1, order => 3);
print "$ref\n$hyp\n$type $score\n";
foreach my $i (1 .. $#{$counts}){
	print STDERR "b$i: " . $counts->[$i]->{correct} . "/" . $counts->[$i]->{total} . "\n";
}



