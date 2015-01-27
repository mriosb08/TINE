#!/usr/bin/perl
use strict;
use List::Util qw(shuffle);
use Getopt::Long "GetOptions";
use verbDB;
use File::Basename;
use directDB;

my ($help, $file, $k, $threshold_a, $threshold_v, $sep, $gs_file, $max, $alch_path, $mln);
$threshold_a = 0.5;
$threshold_v = 0.5;
$k = 10;
$sep = '|||';

$alch_path = '/media/raid-vapnik/mrios/workspace/alchemy/alchemy';
$help=1 unless
&GetOptions( 
	'line-file=s' => \$file,
	'k-fold=s' => \$k,
	'threshold-a=s' => \$threshold_a,
	'threshold-v=s' => \$threshold_v,
	'alchemy-path=s' => \$alch_path,
	'mln=s' => \$mln,
	'max=s' => \$max,
	'sep=s' => \$sep,
	'help' => \$help
);

if ($help || !$file || !$mln){
	print "mln_kfold.pl <options>\n\n",
		"\t--line-file <file>       	The input file in line format to extrat features for db\n",
		"\t--k-fold <number>   			number to define the number of folds (default: 10)\n",
		"\t--mln <file>   				file to MLN rules\n",
		"\t--threshold-v <number>   	number to define the threshold for the simVerb() predicate (default: 0.5)\n",
		"\t--threshold-a <number>   	number to define the threshold for the simArgs() predicate (default: 0.5)\n",
		"\t--max <number>   			number to define the max number of pairs\n",
		"\t--sep <string>   			string to define the separator for strings in token() predicates\n",
		"\t--alchemy-path <string>   	path to alchemy\n",
		"\t--help               		print these instructions\n\n";
	print "implements the following predicates:\n
			VerbsMatch(verb_id, pair_id)
			simVerb(verb_id, sim_v_feature)
			tokenVerb(verb_id, token_v_feature)
			dbVerb(verb_id, db_v_feature)

			ArgsMatch(type_id, verb_id)
			simArgs(type_id, sim_a_feature)
			tokenArgs(type_id, token_a_feature)
			directArgs(type_id, direct_a_feature)
			Entailment(decision, pair_id)\n";
	print "Example: ./mln_kfold_v2.pl --line-file RTE_datasets/MLN-RTE/rte1/rte1_dev.out.line --mln RTE_datasets/MLN-RTE/rte_v3.mln --alchemy-path ../../alchemy/alchemy/ \n";
	exit 1;
}


my $verbdb = new verbDB();

#$file =~ m/^(\w+).\w+$/g;
#my $name  = $1;
my ($name,$path,$suffix) = fileparse($file);
$name = $path.'/'.$name;
my $pairs = loadFile($file);




my @items = shuffle(keys %$pairs);

my $size = scalar(@items);
my $fold_size = int($size / $k);

my $folds = {};
my $fold_num = 0;
my $i = 0;
#print "$fold_size\n";
foreach my $item(@items){
	if($i < $fold_size){
		my $key = $item;
		#print "$key: $i : $fold_num : $pairs->{$key}\n";
		#my $temp = {};
		#$temp->{$key} = $pairs->{$key}; 
		push(@{$folds->{$fold_num}}, $key);
		#print "$key\n";
		$i++;
	}else{
		$fold_num++;
		$i = 0;
	}
}
my @keys_folds = keys %$folds;
my ($avg_acc, $avg_prec, $avg_rec , $avg_f1 , $tot) = (0, 0, 0, 0, 0);

foreach my $i(0..$#keys_folds){
	#test fold
	my $test_fold = ();
	my $train_fold = ();
	push(@$test_fold, $folds->{$i});	
	foreach my $j(0..$#keys_folds){
		if($i != $j){
			#train fold	
			#print "$i:$j $folds->{$j}\n";
			#print Dumper($folds->{$j});		
			push(@$train_fold, $folds->{$j});
		}	
	}
	#train stage
	print "#####TRAIN#####\n";
	
	toDB("$name.train.db", $train_fold, $pairs, 'train');
	callAlchemy($name, $mln, 'train');
	#test stage
	print "#####TEST FOLD($i)#####\n";
	
	toDB("$name.test.db", $test_fold, $pairs, 'test');
	callAlchemy($name, $mln, 'test');
	#eval stage
	my ($acc, $prec, $rec , $f1) = callEval("$name.result", "$name.test.db.gs");
	print "FOLD($i): A:$acc, P:$prec, R:$rec , F1:$f1 \n";
	$avg_acc += $acc;
	$avg_prec += $prec;
	$avg_rec += $rec;
	$avg_f1 += $f1;
	$tot++;	
	#last;
}

printf("AVG FOLDS ACC: %.3f\n",$avg_acc/$tot);
printf("AVG FOLDS PREC: %.3f\n",$avg_prec/$tot);
printf("AVG FOLDS REC: %.3f\n",$avg_rec/$tot);
printf("AVG FOLDS F1: %.3f\n",$avg_f1/$tot);


sub callAlchemy
{
	my ($file, $mln, $type) = @_;
	my $cmd;
	if($type eq 'train'){
		$cmd = "$alch_path/bin/learnwts -d -i $mln -o  $file.out.mln -t $file.train.db -ne Entailment -memLimit 10485760 > $file.train.mln.log";
	}else{
		$cmd = "$alch_path/bin/infer -ms -i $file.out.mln -r $file.result -e $file.test.db -q Entailment > $file.test.mln.log";
		
	}
	#print "cmd:$cmd\n"; 
	system($cmd);
	
}

sub callEval
{
	my ($pred, $gs) = @_;
	my $cmd = "./rte_eval.pl $pred $gs";
	my $result = `$cmd`;
	#print "eval_cmd: $result\n";
	my $acc = 0;
	my $prec  = 0;
 	my $rec = 0; 
	my $f1 = 0;
	($acc, $prec, $rec , $f1) = split(/\s+/, $result);
	return ($acc, $prec, $rec , $f1);
}

sub toDB
{
	my ($file, $folds, $pairs, $type) = @_;
	open(my $O, ">", $file) or die "file not found $file\n";
	open(my $GS, ">", "$file.gs") if($type eq 'test');
	my $keys = ();
	foreach my $fold(@$folds){
		foreach my $item(@$fold){
			push(@$keys, $item);
		}
	}
#	print Dumper($keys);
	my $num_pairs = 0;
	foreach my $pair(@$keys){
		my $v_flag;
		my $i = 0;
		#print STDERR "ID($pair):\n";
		foreach my $value(keys %{$pairs->{$pair}}){
			foreach my $task(keys %{$pairs->{$pair}->{$value}}){
				foreach my $verbs(keys %{$pairs->{$pair}->{$value}->{$task}}){
					my($vt, $vh) = split(/\|\|\|/, $verbs);
					$i++;
					
					#print STDERR "$verbs\n";
					
					my $verb_id = "$pair:$i";
					$v_flag = $verb_id;
					foreach my $score(keys %{$pairs->{$pair}->{$value}->{$task}->{$verbs}}){
						foreach my $arg(keys %{$pairs->{$pair}->{$value}->{$task}->{$verbs}->{$score}}){
								my($arg_t, $arg_h, $score_arg) = split(/\|\|\|/, $pairs->{$pair}->{$value}->{$task}->{$verbs}->{$score}->{$arg});
								my $arg_id = "$verb_id:$arg";
								#print STDERR "\t$arg_t\t$arg_h\n";
								if($score_arg >= $threshold_a){
									print $O "SimArgs(\"$pair\", \"1\")\n";
								}else{
									print $O "SimArgs(\"$pair\", \"0\")\n"; 
								}
								my $args_final = $arg_t.$sep.$arg_h;
								$args_final = clean_string($args_final);
								my $direct_predicate = direct_sem($pair, $arg_t, $arg_h);
								print $O "$direct_predicate\n";
								print $O "TokenArgs(\"$pair\", \"$args_final\")\n" if ($arg_t ne "" and $arg_h ne "");
								#print $O "ArgsMatch(\"$pair\", \"$verb_id\")\n";
																										
						}
						my $result_db = $verbdb->get_verb_entailment($vt, $vh);
						print $O "DBVerb(\"$verb_id\", \"$result_db\")\n";
						if($score >= $threshold_v){
							print $O "SimVerb(\"$pair\", \"1\")\n";
						}else{
							print $O "SimVerb(\"$pair\", \"0\")\n";
						}					
					}
					$vt = clean_string($vt);
					$vh = clean_string($vh);
					print $O "TokenVerb(\"$pair\", \"$vt$sep$vh\")\n" if ($vt ne "" and $vh ne "");
					#print $O "VerbsMatch(\"$verb_id\", \"$pair\")\n";	
				}
			}
			if($value == 1){
				$value = 'true';
			}else{
				$value = 'false';
			}
			print $O "Entailment(\"$value\", \"$pair\")\n" if($type eq 'train');
			print $GS "$pair\t$value\n" if($type eq 'test');
			
		}
		$num_pairs++;
		if($num_pairs >= $max){
			print STDERR "MAX number of pairs: $max\n" if($max);
			last if($max);
		}
	}
	close($O);
	close($GS) if ($type eq 'test');
}



sub loadFile
{
	my $file = shift;

	my $pairs = {};
	open(my $IN, "<", $file) or die "file $file not found\n";
	while(my $line = <$IN>){
		chomp($line);
		#e.g. 3|||0|||IE|||comment|||work|||0.410405|||A0|||0.5|||ECB spokeswoman , Regina Schueller ,|||Regina Shueller 
		my($id, $value,$task, $vt, $vh, $score_verb, $arg, $score_arg, $arg_t, $arg_h) = split(/\|\|\|/, $line);
		$pairs->{$id}->{$value}->{$task}->{$vt.$sep.$vh}->{$score_verb}->{$arg} = $arg_t.$sep.$arg_h.$sep.$score_arg;
		
		
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
	$string =~ s/"//g;
	$string =~ s/'//g;
	$string =~ s/,//g;
	$string =~ s/-//g;
	$string =~ s/\@//g;
	$string =~ s/\.//g;
	$string =~ s/\s+/ /g;
	return $string;
}

sub direct_sem
{
	my($id, $arg_t, $arg_h) = @_;
	my $result = 0;
	my @lhs = split(/\s+/, $arg_t);
	my @rhs = split(/\s+/, $arg_h);
	my $direct_db = new directDB();
	#$direct_db->get_token_entailment($token_a, $token_b);
	my @ent_decision = ();
	foreach my $token_lhs(@lhs){
		my @token_decision = ();
		my $true_flag = 0;		
		foreach my $token_rhs(@rhs){
			my $ent = $direct_db->get_token_entailment($token_lhs, $token_rhs);
			#push(@token_decision, $ent);
			if($ent == 1){
				$true_flag = 1;			
			}
		}
		if($true_flag == 1){
			push(@ent_decision, 1);
		}else{
			push(@ent_decision, 0);
		}
		
	}
	$result = vote_mayor(\@ent_decision);
	my $predicate = "DirectArgs(\"$id\", \"$result\")";
	return $predicate;
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
	if($true >= $false){
		return 1;	
	}else{
		return 0;
	}
}

