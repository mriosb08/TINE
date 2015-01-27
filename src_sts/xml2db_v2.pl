#!/usr/bin/perl
use strict;
use XML::Simple;
use Data::Dumper;
use Getopt::Long "GetOptions";
use verbDB;
my ($help, $file, $output, $in_type, $threshold_a, $threshold_v, $sep, $gs_file, $max);
$threshold_a = 0.5;
$threshold_v = 0.5;
$in_type = 'train';
$sep = '|||';
$help=1 unless
&GetOptions( 
	'xml-file=s' => \$file,
	'db-output=s' => \$output,
	'type=s' => \$in_type,
	'threshold-a=s' => \$threshold_a,
	'threshold-v=s' => \$threshold_v,
	'gs-file=s' => \$gs_file,
	'max=s' => \$max,
	'sep=s' => \$sep,
	'help' => \$help
);

if ($help || !$file || !$output){
	print "xml2db_v2.pl <options>\n\n",
		"\t--xml-file <file>       	The input file in xml format to extrat features for db\n",
		"\t--db-output <file>    	name for the output database for MLN (Alchemy format)\n",
		"\t--type <string>   		string to define the output type [train|test] (default: train)\n",
		"\t--threshold-v <number>   number to define the threshold for the simVerb() predicate (default: 0.5)\n",
		"\t--threshold-a <number>   number to define the threshold for the simArgs() predicate (default: 0.5)\n",
		"\t--max <number>   		number to define the max number of pairs\n",
		"\t--sep <string>   		string to define the separator for strings in token() predicates\n",
		"\t--gs-file <file>   		file to output gs file in testing mode\n",
		"\t--help               	print these instructions\n\n";
	print "implements the following predicates:\n
			VerbsMatch(verb_id, pair_id)\n
			simVerb(verb_id, sim_v_feature)\n
			tokenVerb(verb_id, token_v_feature)\n
			dbVerb(verb_id, db_v_feature)\n
			ArgsMatch(type_id, verb_id)\n
			simArgs(type_id, sim_a_feature)\n
			tokenArgs(type_id, token_a_feature)\n
			nellArgs(type_id, nell_a_feature)\n
			Entailment(decision, pair_id) \n";
	exit 1;
}


my $xml = new XML::Simple;
my $data = $xml->XMLin($file, KeyAttr => ('id'), ForceArray => 1);
#print Dumper($data);

my $verbs = {};
my $argu = {};
my $sim_arg = {};
my $sim_verb = {};
my $token_arg = {};
my $token_verb = {};
my $db_verb = {};
my $nell_arg = {};

my $decisions = {};

my $verbdb = new verbDB();
my $GS;
if($gs_file){
	open($GS, ">:utf8", $gs_file) or die "file $gs_file not found\n";
}

my $i = 0;
foreach my $pair(keys %{$data->{pair}}){
	print STDERR "ID($pair)\n";
	my $entailment = $data->{pair}->{$pair}->{entailment};
	foreach my $targets(keys %{$data->{pair}->{$pair}->{alignment}->[0]->{v2v}}){
		my $t_target = "";
		my $h_target = "";
		$t_target = $data->{pair}->{$pair}->{alignment}->[0]->{v2v}->{$targets}->{T}->[0]->{vt}->[0]->{content};
		$h_target = $data->{pair}->{$pair}->{alignment}->[0]->{v2v}->{$targets}->{T}->[0]->{vh}->[0]->{content};
		my $verb_score = $data->{pair}->{$pair}->{alignment}->[0]->{v2v}->{$targets}->{combo};
		print STDERR "T:$t_target\tH:$h_target \tSCORE:$verb_score\n";
		$t_target = clean_string($t_target);
		$h_target = clean_string($h_target);
		my $verb_pair;
		if($t_target eq "" and $h_target eq ""){
			next;
		}else{
			$i++;
		}
		last if($i >= $max);		
		#args features
		foreach my $args(keys %{$data->{pair}->{$pair}->{alignment}->[0]->{v2v}->{$targets}}){
				#print "ARGS:$args\n";
				if($args =~ m/[A-Z]+/ and $args !~ m/T/){
					my $t_arg = $data->{pair}->{$pair}->{alignment}->[0]->{v2v}->{$targets}->{$args}->[0]->{t}->[0];
					my $h_arg = $data->{pair}->{$pair}->{alignment}->[0]->{v2v}->{$targets}->{$args}->[0]->{h}->[0];
					my $arg_score = $data->{pair}->{$pair}->{alignment}->[0]->{v2v}->{$targets}->{$args}->[0]->{score};
					print STDERR "\tARG:$args\tSCORE:$arg_score\n\t\tT:$t_arg\n\t\tH:$h_arg\n";
					$t_arg = clean_string($t_arg);
					$h_arg = clean_string($h_arg);
					my $args_final = $t_arg.$sep.$h_arg;
					$verb_pair = "$pair:$targets";
					my $typye_id = "$pair:$args";
					my $sim_a = "simArgs(\"$typye_id\", \"0\")";
					if($arg_score >= $threshold_a){
						$sim_a = "simArgs(\"$typye_id\", \"1\")";
					}
					
					my $args_verb = "ArgsMatch(\"$typye_id\", \"$verb_pair\")";
					my $t_arg = "tokenArgs(\"$typye_id\", \"$args_final\")";
					
					
					$sim_arg->{$sim_a} =  $sim_a if($typye_id ne "");
					
					$token_arg->{$t_arg} =  $t_arg if($typye_id ne "" and $args_final ne "");
					
					$argu->{$args_verb} =  $args_verb if($args =~ m/[A-Z]+/ and $typye_id ne "" and $verb_pair ne "");
					# TODO modifiers
				}
		}
		#verbs features
		my $result_db = $verbdb->get_verb_entailment($t_target, $h_target);
		my $db_v = "dbVerb(\"$verb_pair\", \"$result_db\")";
		
		$db_verb->{$db_v} = $db_v if($verb_pair ne "" and $result_db ne "");
		my $sim_v = "simVerb(\"$verb_pair\", \"0\")";
		if($verb_score >= $threshold_v){
			$sim_v = "simVerb(\"$verb_pair\", \"1\")";
		}

		$sim_verb->{$sim_v} = $sim_v if($verb_pair ne "");
		my $verbs_match = "VerbsMatch(\"$verb_pair\", \"$pair\")";
		my $v = $t_target.$sep.$h_target;		
		my $t_verb = "tokenVerb(\"$verb_pair\", \"$v\")";
		
		$verbs->{$verbs_match} = $verbs_match if($verb_pair ne "" and $pair ne "");
		
		$token_verb->{$t_verb} = $t_verb if($verb_pair ne "" and $v ne "");

		if($entailment == 1){
			$entailment = 'true';
		}else{
			$entailment = 'false';
		}
		my $entailment_decision = "Entailment(\"$entailment\", \"$pair\")";
		print $GS "$pair\t$entailment\n" if($gs_file and $entailment);
		
		$decisions->{$entailment_decision} = $entailment_decision if($entailment ne "" and $pair ne "");
		
	}

	
}
open(my $OUT, ">", $output) or die "file $output not found\n";

print_DB($verbs, $OUT);
print_DB($token_verb, $OUT);
print_DB($sim_verb, $OUT);
print_DB($db_verb, $OUT);
print_DB($argu, $OUT);
print_DB($token_arg, $OUT);
print_DB($sim_arg, $OUT);
print_DB($decisions, $OUT) if($in_type eq 'train');
close($OUT);

sub print_DB
{
	my ($elements, $FILE) = @_;
	foreach my $elem(keys %$elements){
		print $FILE "$elem\n";
	}
}

sub clean_string
{
	my $string = shift;
	$string =~ s/"/\@Q\@/g;
	return $string;
}

sub direct_sem
{
	my($arg_t, $arg_h) = @_;
	my $result;
	my $lhs = split(/\s+/, $arg_t);
	my $rhs = split(/\s+/, $arg_h);
	my $direct_db = new directDB();
	#$direct_db->get_token_entailment($token_a, $token_b);
	my @ent_decision = ();
	foreach my $token_lhs(@$lhs){
		my @token_decision = ();		
		foreach my $token_rhs(@$rhs){
			my $ent = $direct_db->get_token_entailment($token_lhs, $token_rhs);
			push(@token_decision, $ent);
		}
		push(@ent_decision, vote_mayor(\@token_decision));
	}
	$result = vote_mayor(\@ent_decision);
	return $result;
}

sub vote_mayor
{
	my $token_decision = shift;	
	my $true = 0;
	my $false = 0;
	foreach my $decision(@$token_decision){
		if($decision == 1){
			$true++;		
		}elsif($decision == 0){
			$false++;
		}
	}
	if($true > $false){
		return 1;	
	}else{
		return 0;
	}
}
