#!/usr/bin/perl
use strict;

use Getopt::Long "GetOptions";
use verbDB;
my ($help, $file, $output, $in_type, $threshold_a, $threshold_v, $sep, $gs_file, $max);
$threshold_a = 0.5;
$threshold_v = 0.5;
$in_type = 'train';
$sep = '|||';
$help=1 unless
&GetOptions( 
	'line-file=s' => \$file,
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
	print "line2db.pl <options>\n\n",
		"\t--line-file <file>       	The input file in line format to extrat features for db\n",
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






my $verbdb = new verbDB();
my $GS;
if($gs_file){
	open($GS, ">:utf8", $gs_file) or die "file $gs_file not found\n";
}

my $pairs = loadFile($file);
open(my $O, ">", $output) or die "file $output not found\n";

my $num_pairs = 0;
foreach my $pair(keys %$pairs){
	my $v_flag;
	my $i = 0;
	
	foreach my $value(keys %{$pairs->{$pair}}){
		foreach my $task(keys %{$pairs->{$pair}->{$value}}){
			foreach my $verbs(keys %{$pairs->{$pair}->{$value}->{$task}}){
				my($vt, $vh) = split(/\|\|\|/, $verbs);
				$i++;
				
				#print "$num_pairs:$max\n";
				
				my $verb_id = "$pair:$i";
				$v_flag = $verb_id;
				foreach my $score(keys %{$pairs->{$pair}->{$value}->{$task}->{$verbs}}){
					foreach my $arg(keys %{$pairs->{$pair}->{$value}->{$task}->{$verbs}->{$score}}){
							my($arg_t, $arg_h, $score_arg) = split(/\|\|\|/, $pairs->{$pair}->{$value}->{$task}->{$verbs}->{$score}->{$arg});
							my $arg_id = "$verb_id:$arg";
							
							if($score_arg >= $threshold_a){
								print $O "simArgs(\"$arg_id\", \"1\")\n";
							}else{
								print $O "simArgs(\"$arg_id\", \"0\")\n"; 
							}
							my $args_final = "$arg_t|||$arg_h";
							$args_final = clean_string($args_final);
							print $O "tokenArgs(\"$arg_id\", \"$args_final\")\n";
							print $O "ArgsMatch(\"$arg_id\", \"$verb_id\")\n";
																									
					}
					my $result_db = $verbdb->get_verb_entailment($vt, $vh);
					print $O "dbVerb(\"$verb_id\", \"$result_db\")\n";
					if($score >= $threshold_v){
						print $O "simVerb(\"$verb_id\", \"1\")\n";
					}else{
						print $O "simVerb(\"$verb_id\", \"0\")\n";
					}					
				}
				$verbs = clean_string($verbs);
				print $O "tokenVerb(\"$verb_id\", \"$verbs\")\n";
				print $O "VerbsMatch(\"$verb_id\", \"$pair\")\n";	
			}
		}
		if($value == 1){
			$value = 'true';
		}else{
			$value = 'false';
		}
		print $O "Entailment(\"$value\", \"$pair\")\n" if($v_flag and ($in_type eq 'train'));
		print $GS "$pair\t$value\n" if($gs_file and $value);
			
	}
	$num_pairs++;
	if($num_pairs >= $max){
		print "MAX number of pairs: $max\n";
		last;
	}
}


#print_DB($verbs, $OUT);
#print_DB($token_verb, $OUT);
#print_DB($sim_verb, $OUT);
#print_DB($db_verb, $OUT);
#print_DB($argu, $OUT);
#print_DB($token_arg, $OUT);
#print_DB($sim_arg, $OUT);
#print_DB($decisions, $OUT) if($in_type eq 'train');
close($O);

sub loadFile
{
	my $file = shift;

	my $pairs = {};
	open(my $IN, "<", $file) or die "file $file not found\n";
	while(my $line = <$IN>){
		chomp($line);
		#e.g. 3|||0|||IE|||comment|||work|||0.410405|||A0|||0.5|||ECB spokeswoman , Regina Schueller ,|||Regina Shueller 
		my($id, $value,$task, $vt, $vh, $score_verb, $arg, $score_arg, $arg_t, $arg_h) = split(/\|\|\|/, $line);
		$pairs->{$id}->{$value}->{$task}->{"$vt|||$vh"}->{$score_verb}->{$arg} = "$arg_t|||$arg_h|||$score_arg";
		
		
	}
	return $pairs;
}

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

