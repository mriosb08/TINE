#!/usr/bin/perl
use wnDB;
use vnDB;
use voDB;
use quitSW;
use Meteor;
use NELL;
use setOperations;
use verbDB;
use vnSQL;
use directDB;
use Set::Scalar;
use strict;

my $text = 'Prince Charles was previously married to Princess Diana , who died in a car crash in Paris in August 1997 .';
my $hypo = 'Prince Charles and Princess Diana got married in August 1997 .';

my @T = split(/\s+/, $text);
my @H = split(/\s+/, $hypo);

print "WN TEST\n";

my $wn = new wnDB();
my $pos = $wn->penn_to_wn_pos('NN');
my $hyp_tree = $wn->get_hyper_tree('car', $pos);
print "car.$pos.01\n";
foreach my $key(keys %$hyp_tree){
	#print "@{$hyp_tree->{$key}}\n";
	my @temp = @{$hyp_tree->{$key}}; 
	print "@temp\n";
}

print "VN TEST\n";
print "verb: die\n";
my $vn = new vnDB();
my $classes = $vn->get_vn_classes('run');
foreach my $key(keys %$classes){
	my @temp = @{$classes->{$key}}; 
	print "@temp\n";
}

print "VO TEST\n";
print "verb: run verb: race\n";
my $vo = new voDB();
my $relations = $vo->get_vo('run', 'race');
foreach my $key(keys %$relations){
	#print "$relations->{$key}\n";
	my @temp = @{$relations->{$key}}; 
	print "@temp\n";
}

print "quitSW TEST\n";
print "T:$text\n";

my $sw = new quitSW();
my $sw_text = $sw->quit_sw(\@T);
$sw_text = join(' ', @{$sw_text});
print "$sw_text\n";
my $set_text = $sw->to_set(\@T);
print "$set_text\n";

print "METEOR TEST\n";
print "T:$text \nH:$hypo\n";
#my $meteor = new Meteor();
#my $score = $meteor->get_meteor($text, $hypo);

#print "SCORE:$score\n";

print "NELL TEST\n";
my $concept = 'nick-hornby';
print "named_entity: $concept\n";
my $nell = new NELL();
#my $beliefs = $nell->get_beliefs('About a Boy');
#foreach my $key(keys %$beliefs){
	#print "@{$beliefs->{$key}}\n";
#	foreach my $ref(@{$beliefs->{$key}}){
#		print "R:\n";#
#		foreach my $key(keys %$ref){
#			print "$ref->{$key}\n";
#		}
#		print "#####\n";
#	}
#}
my $categories = $nell->get_categories($concept);
print "CATEGORIES:\n";
foreach my $key(keys %$categories){
	print "$categories->{$key}\n";
}
my $relations = $nell->get_relations($concept);
print "RELATIONS:\n";
foreach my $key(keys %$relations){
	print "$key:\n\t",join('|||', @{$relations->{$key}}),"\n";
} 
print "values for city\n";
my $values = $nell->get_values('city');
my $value;
foreach my $key(keys %$values){
	#print "@{$values->{$key}}\n";
	$value = @{$values->{$key}}[0];	
}

print "instances for city:$value\n";
my $instances = $nell->get_instances('city', $value);
foreach my $key(keys %$instances){
	print "@{$instances->{$key}}\n";
} 


print "TEST SET_OPER\n";
#TODO hash to array
# my @array = map { $hash{$_} } sort { $a<=>$b } keys %hash;
my $set_oper = new setOperations(set_1 => \@T, set_2 => \@H);

print "cosine:", $set_oper->get_cosine(),"\n";
print "dice:", $set_oper->get_dice(),"\n";
print "jaccard:", $set_oper->get_jaccard(),"\n";
print "overlap:", $set_oper->get_overlap(),"\n";
print "precision:", $set_oper->get_precision(),"\n";
print "recall:", $set_oper->get_recall(),"\n";
print "F1: ",$set_oper->get_f1(),"\n";

print "TEST VERBDB\n";
my $verb_a = 'slaughter';
my $verb_b = 'kill';

my $verbdb = new verbDB();
my $result = $verbdb->get_verb_entailment($verb_a, $verb_b);
print "$verb_a:$verb_b => $result\n";

print "TEST SQL VN\n";
my $verb_a = 'slaughter';
my $verb_b = 'kill';
my $vnsql = new vnSQL(strict=>0);
my ($result, $class_a, $class_b) = $vnsql->getIclass($verb_a, $verb_b);
print "$verb_a:$verb_b => $result\n";
print "class_a: ", join(' ', $class_a->members),"\n";
print "class_b: ", join(' ', $class_b->members),"\n"; 

print "TEST direct DB\n";
my $token_a = 'koala';
my $token_b = 'animal';
my $direct_db = new directDB();
print "koala=>animal\n";
print "score:".$direct_db->get_score($token_a, $token_b)."\n";
print "animal=>koala\n";
print "score:".$direct_db->get_score($token_b, $token_a)."\n";
print "koala=>animal\n";
print "etails:".$direct_db->get_token_entailment($token_a, $token_b)."\n";
print "animal=>koala\n";
print "etails:".$direct_db->get_token_entailment($token_b, $token_a)."\n";

