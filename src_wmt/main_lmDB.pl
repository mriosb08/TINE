#!/usr/bin/perl
use lmDB;

my $lm = new lmDB();
@sentence = qw /differential equation/;


$in = $lm->getLM(\@sentence);

print "LM:$in\n";

@sentence = qw /equation differential/;
$in = $lm->getLM(\@sentence);
 print "LM:$in\n";
