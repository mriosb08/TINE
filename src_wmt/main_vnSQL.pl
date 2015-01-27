#!/usr/bin/perl
use vnSQL;

my $vn = new vnSQL();
$verb_a = 'eat';
$verb_b = 'devour'; #create
$result = $vn->getIclass($verb_a,$verb_b);

print "share a class\n" if ($result != 0);



