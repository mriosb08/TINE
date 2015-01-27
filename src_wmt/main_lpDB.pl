#!/usr/bin/perl
use lpDB;

my $lp = new lpDB();
$word_a = 'dog';
$word_b = 'cat';

$in = $lp->getLP($word_a,$word_b);

print "IN:$in\n";
