#!/usr/bin/perl
use voDB;

my $vo = new voDB();
$verb_a = 'eat';
$verb_b = 'devour';
$vo->setVerbs($verb_a,$verb_b);
$relation = $vo->getRelation();
@vector = $vo->getVector();
print "RELATION: $relation \n@vector\n";

