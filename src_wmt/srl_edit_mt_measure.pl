#!/usr/bin/perl

use strict;
use vnSQL;
use voDB;
use simsDB;
use lpDB;
use lmDB;
use List::Util qw(max);
use Tie::IxHash; 
#

use Getopt::Long "GetOptions";
use ColumnReader;


my ($help,$reference,$system,$verbnet,$verbOcean,$log,$conll_config,$verbose,$blank,$type,$arg_content,$lang_pair,$test_set,$system_id,$final_score_type,$train,$back);

my (%reference,%system,%conll) = ();
$verbose = 1;
$arg_content = 'word'; 
$type = 'number';
$final_score_type = 'wa'; 	 #final score weight average
my $alpha = 1;
my $beta = 1;
$train = 0;
$back = 0;
my @vo_relations = ('can-result-in',
		'happens-before',
		'low-vol',
		'opposite-of',
		'similar',
		'stronger-than',
		'unk',
		);

$help=1 unless
&GetOptions(
	'reference=s' => \$reference,
	'system=s' => \$system,
	'conll-format=s' => \$conll_config,
	'argument-content=s' => \$arg_content,
	'final-score=s' => \$final_score_type,
	'alpha=s' => \$alpha,
	'beta=s' => \$beta,
	'edit-eval=s' => \$type,
	'lang-pair=s' => \$lang_pair,
	'test-set=s' => \$test_set,
	'back' => \$back,
	'system-id=s' => \$system_id,
	'train' => \$train,
	'verbose' => \$verbose,	
	'help' => \$help
);



if ($help || !$reference || !$system || !$conll_config || !$lang_pair || !$test_set || !$system_id){
	print "srl_edit_mt_measure.pl <options>\n\n",
		"\t--reference	<file>                         file with reference sentences (conll format)\n",
		"\t--system	<file>                         file with system sentences (conll format)\n",
		"\t--lang-pair	<string>                       string with the language pair\n",
		"\t--test-set	<string>                       string with the id of the test set\n",
		"\t--system-id	<string>                       string with the id of the system to be tested\n",
		"\t--conll-format	<file>                 file with the information about the conll columns (column-name position)\n",
		"\t--argument-content	<string>	       type of content for eval arguments, types word,lemma (default: word)\n",
		"\t--edit-eval		<string>	       type of edit evalutation, types number,lm (default: number)\n",
		"\t--final-score	<string>	       type of final score, types wa f1 (default: wa)\n",
		"\t--alpha		<num>		       the fluency parameter implies wa as final_score (default: 1)\n",
		"\t--beta		<num>		       the adequacy parameter implies wa as final_score (default: 1)\n",
		"\t--train				       output for training data, adequacy and fluency intead of final-score\n",
		"\t--back				       use fluency as backoff\n",
		"\t--verbose	<level>                        print log (default: 1)\n",
		"\t--help              	                       print these instructions\n\n",
		"EXAMPLE: perl -Ireader srl_edit_mt_measure.pl --reference example/newssyscombtest2011-ref.en.sgm.srl.tt --system example/newssyscombtest2011.es-en.alacant.sgm.srl.tt --conll-format conll_config.txt --lang-pair es-en --test-set newssyscombtest --system-id alacant\n";

	exit 1;
}

$log = "$system.edit.log";
$blank = '-';



my $columnReader_reference = new ColumnReader(file => $reference, trim => 1);
my %columns_reference;

my $columnReader_system = new ColumnReader(file => $system, trim => 1);
my %columns_system;
my $LOG;
if($verbose){
	open($LOG,">",$log) or die "Could not open file: $log\n"; #log
}
open(my $OUT,">","$system.edit.$type.segment.out") or die "Could not open file: $system.edit.$type.segment.out\n"; #output
open(my $OUT_S,">","$system.edit.$type.system.out") or die "Could not open file: $system.edit.$type.system.out\n"; #output
&loadConllFormat($conll_config); #load the format of the conll files (column-name position)

my $segment = 0; #counter of segments
my $sum_system = 0;
my $doc_flag = 0;
while ($columnReader_reference->readNext(\%columns_reference) && $columnReader_system->readNext(\%columns_system)){
	
	$segment++;

	my $srl_start;
	my $segment_score = 0;
	my $adequacy_score = 0;
 	my $fluency_score = 0;

	foreach my $key(keys(%conll)){
		if($conll{$key} eq 'srl'){
			$srl_start = $key; # position of the srl structures
		}
	}
	
		
	###fill system hash
	my $i=0;
	foreach my $column_s(keys(%columns_system)){
		my $feature = $conll{$column_s}; #change positions to names
		
		if($column_s >= $srl_start){
			
			$system{"srl-$i"} = $columns_system{$column_s};			
			$i++;	
		}else{
			$system{$feature} = $columns_system{$column_s};
			
		}
	}
	
	###fill ref hash
	$i=0;
	foreach my $column_r(keys(%columns_reference)){
		my $feature = $conll{$column_r}; #change positions to names
		
		if($column_r >= $srl_start){
			
			$reference{"srl-$i"} = $columns_reference{$column_r};
			$i++;
				
		}else{
			$reference{$feature} = $columns_reference{$column_r};
		}
	}
	#if the doc has doc-id
	if(exists($system{'doc_id'})){
		$doc_flag = 1;
	}

	###################################	
	if($verbose){
		print $LOG "SEGMENT: $segment\n";		
		print $LOG "\tREFERENCE: $reference{'word'}\n";
		
		print $LOG "\tSYSTEM: $system{'word'}\n";
		
	}
	
	###Processing#####

	###Fluency#######
	$fluency_score = chunk_matcher($segment,\%system,\%reference);
	print $LOG "SEGMENT: $segment\tfluency = $fluency_score\n" if ($verbose);
	
	#################
	###Adequacy#######
	print $LOG "SEGMENT: $segment\tsys_targets = $system{'target'}\n" if ($verbose);
	print $LOG "SEGMENT: $segment\tref_targets = $reference{'target'}\n" if ($verbose);
	my ($edit_score,$matrix) = srl_verb_aligner($segment,\%system,\%reference,$srl_start); #adequacy, if no targets 0
	
	if($matrix != 0) #final score based on a matrix of srl's scores
	{
		
			$adequacy_score  = $edit_score;
		
		 print $LOG "SEGMENT: $segment\tadequacy = $adequacy_score \n" if ($verbose); #average arguments over the number of matched verbs
	}else{
	   $adequacy_score = 0; #score 0
	   print $LOG "SEGMENT: $segment\tadequacy = $adequacy_score\n" if ($verbose);
	}
	#print $LOG "SEGMENT: $segment\tadequacy = $edit_score\n" if ($verbose);
			
	##################
	my $final_score = 0;
	
	if($final_score_type eq 'wa'){
		$final_score = (($alpha*$fluency_score)+($beta*$adequacy_score))/($alpha+$beta); #wieght average
	}elsif($final_score_type eq 'f1'){
		
		$final_score = (2*($fluency_score*$adequacy_score))/($fluency_score+$adequacy_score);
	}
	if($back){
		if($adequacy_score == 0){
			$final_score = $fluency_score;
		}else{
			$final_score = $adequacy_score;
		}
	}
	print $LOG "SEGMENT: $segment\tfinal_score  ($final_score_type) = $final_score \n" if ($verbose);
	print $LOG "\n" if($verbose);
	
	if($doc_flag == 0){ #id there is no doc_id just consecutive segments
		print $OUT "TINE-srl_edit\t$lang_pair\t$test_set\t$system_id\t$segment\t$final_score\n";
	}else{

		my ($doc,@col_d) = split(/\s+/,$system{'doc_id'});
		my ($seg,@col_s) = split(/\s+/,$system{'segment'});
		#print "id: $system{'doc_id'}\n$system{'segment'}\n";
		if($train){ #if the user wants to train the alpha and beta parameters
			print $OUT "TINE-srl_edit\t$lang_pair\t$test_set\t$system_id\t$doc\t$seg\t$fluency_score\t$adequacy_score\n";
		}else{
			print $OUT "TINE-srl_edit\t$lang_pair\t$test_set\t$system_id\t$doc\t$seg\t$final_score\n";
		}
		
	}
	$sum_system += $final_score;
	%system = ();
	%reference = ();
}

$sum_system = $sum_system/$segment;
print $LOG "SYSTEM_SCORE: $sum_system\n" if($verbose);
print $OUT_S "TINE-srl_edit\t$lang_pair\t$test_set\t$system_id\t$sum_system\n";
########
# Input: file whit columns and positions
# Output: hash: key->column-name data-> position

sub loadConllFormat
{
	my($conll_file) = shift;

	open(my $FILE,"<",$conll_file) or die "Could not open file: $conll_file\n";
	while (my $line = <$FILE>){
		chomp($line);		
		if($line !~ m/^#/){
			my($col_name,$position) = split(/\s+/,$line);			
			$conll{$position} = $col_name;
		}
	}
	
}
###########
# Input: segment number, system content, reference content, start of srl
# Output: align matrix ??
#
#
sub srl_verb_aligner
{
	my($segment,$sys,$ref,$srl_start) = @_;
	#first extract targets
	my @targets_sys = split(/\s+/,$sys->{'target'});
	my @targets_ref = split(/\s+/,$ref->{'target'});
	
	my $overall_result = 0;
	
	my @lemma_sys = split(/\s+/,$sys->{'lemma'});
	my @lemma_ref = split(/\s+/,$ref->{'lemma'});

	my %verb_matrix = ();
	my $v_i = 0;
	my $v_j = 0;
	my $num_of_cols_sys = keys(%{$sys});
	my $num_of_cols_ref = keys(%{$ref});	
	my $verb_sum = 0;
	my $num_of_verbs = 0;
	if($srl_start+1 <= $num_of_cols_sys && $srl_start+1 <= $num_of_cols_ref){ #if the system and ref has targets
	#second aling targets using lemmas
		foreach my $i(0..$#targets_sys){ #foreach target of the system compare it to each target of the reference

			next if($targets_sys[$i] eq $blank);
				my $verb_sys = $lemma_sys[$i];
				
			foreach my $j(0..$#targets_ref){

				next if($targets_ref[$j] eq $blank);		
					my $verb_ref = $lemma_ref[$j];
					my $result = 0;
					if($verb_sys eq $verb_ref){ #if the verbs are the same
						$result = 1;
						print $LOG "SEGMENT: $segment\t$verb_sys eq $verb_ref\n" if ($verbose);
					}else	#how related they are using verbnet and verbocean
					{
						print $LOG "SEGMENT: $segment\tverbs: $verb_sys,$verb_ref\n" if ($verbose);
						$result = verbDecision($verb_sys,$verb_ref,$segment);
						
						
					}
					if($result == 1){ #compare srl structures
						$overall_result = srl_edit($sys,$ref,$v_i,$v_j,$segment,$verb_sys,$verb_ref);					$verb_sum += $overall_result;
						#how to score verb + args
						#????????????????????
						$verb_matrix{$verb_sys}{$verb_ref} = $overall_result;
						$num_of_verbs++;  
					}				
					
					$v_j++; #verb ref number			
			}
			$v_j = 0;
			$v_i++; #verb system number
		}
		$v_i = 0;
	}else{
		print $LOG "SEGMENT: $segment\tSYSTEM or REF has no targets\n" if ($verbose);
		###
		return 0;
	}
	
	if($num_of_verbs != 0){
		$verb_sum = $verb_sum/$num_of_verbs;
	}else{
		$verb_sum = 0;
	}
	
	
	return ($verb_sum,\%verb_matrix);	
}
#########
#In: verb a verb b
#Out: 1 if they are related 0 otherwise
####

sub verbDecision
{
	my($verb_sys,$verb_ref,$segment) = @_;	
		
	my $vn = new vnSQL(); #verbnet interface
	$verb_sys =~ s/'/\\'/g;
	$verb_ref =~ s/'/\\'/g;
	my $vn_result = $vn->getIclass($verb_sys,$verb_ref);
	
	
	if($vn_result == 1){  		#the main decision is from verbnet
		print $LOG "SEGMENT: $segment\tverbs eq decision taken by VerbNet\n" if ($verbose);
		return 1;
		
	}else{ 				#backoff from verbOcean
		my $vo = new voDB();
		$vo->setVerbs($verb_sys,$verb_ref);
		my $vo_relation = $vo->getRelation();
	
		if($vo_relation eq 'opposite-of' || $vo_relation eq 'unk'){
		print $LOG "SEGMENT: $segment\tverbs ne decision taken by VerbOcean\n" if ($verbose);
			return 0;			
		}else{
		print $LOG "SEGMENT: $segment\tverbs eq decision taken by VerbOcean\n" if ($verbose); 
			return 1; # we take all the other relations as similar			
		}
		
	}	
		 
}
######
#In: system, reference, position of argument in system, position of argument in reference
#out: score, average of related arguments  

sub srl_edit
{
	my ($sys,$ref,$position_sys,$position_ref,$segment,$v_sys,$v_ref) =  @_;
	my $result = 0;	
	my (%args_sys, %args_ref)= ();
	tie %args_sys, "Tie::IxHash";
	tie %args_ref, "Tie::IxHash";	
	#first extract words
	my @content_sys;
	my @content_ref;
	#TODO later put option to lemmas
	if($arg_content eq 'word'){
		@content_sys = split(/\s+/,$sys->{'word'});
		@content_ref = split(/\s+/,$ref->{'word'});
	}elsif($arg_content eq 'lemma')
	{
		@content_sys = split(/\s+/,$sys->{'lemma'});
		@content_ref = split(/\s+/,$ref->{'lemma'});
		
	}
	
	#second extract srl (srl starts at 0)
	
	my @srl_sys = split(/\s+/,$sys->{"srl-$position_sys"});
	my @srl_ref = split(/\s+/,$ref->{"srl-$position_ref"});
	
	print $LOG "SEGMENT: $segment\t sys: $v_sys($position_sys)->@srl_sys ref: $v_ref($position_ref)->@srl_ref\n" if ($verbose);
	#attach words to arguments
	foreach my $i(0..$#srl_sys){
		if($srl_sys[$i] !~ m/^\w+-V$/ && $srl_sys[$i] !~ m/^O$/){ # if is not a verb or empty
			$srl_sys[$i] =~ m/^\w+-(.*)$/;	#extract argument
			my $argument = $1;		
			$args_sys{$argument} .= $content_sys[$i].' ';
			
		}
	}
	
	foreach my $i(0..$#srl_ref){
		if($srl_ref[$i] !~ m/^\w+-V$/ && $srl_ref[$i] !~ m/^O/){ # if is not a verb or empty
			$srl_ref[$i] =~ m/^\w+-(.*)$/;	#extract argument
			my $argument = $1;				
			$args_ref{$argument} .= $content_ref[$i].' '; 
			
		}
	}

	##compare same arguments 
	#create a matrix of editions just diagonal	
	my @edit_operations = ();
	my $lm;
	my @content_arg_ref;
	my $ref_lm;
	if($type eq 'lm'){
		$lm = new lmDB();
		@content_arg_ref = extract_content(\%args_ref); #extract content from args
		$ref_lm = $lm->getLM(\@content_arg_ref);
	}
	
	
	my $sum = 0;
	foreach my $arg_sys(keys(%args_sys)){
		foreach my $arg_ref(keys(%args_ref)){
			#next if(!exists($args_sys{$arg_ref}));
			if($arg_sys eq $arg_ref){ #if is the same argument 
				if($args_sys{$arg_sys} ne $args_ref{$arg_ref}){ #if the content is not the same
					#apply substitution of content of sys
	
					$args_sys{$arg_sys} = $args_ref{$arg_ref};
					push(@edit_operations,"substitution $arg_sys $args_ref{$arg_ref}");
					if($type eq 'lm'){
						my @temp_sys = extract_content(\%args_sys);
						my $sys_lm = $lm->getLM(\@temp_sys);
						$sum += ($ref_lm-$sys_lm); 
					}
					  # diference between the language models  
					   #compute cost
						
				}					
			}else{
				if(!exists($args_sys{$arg_ref})){ #if the argument of ref is not in sys  
					#apply insert of arg and content sys
					#TODO put the new in the same position as in ref
					$args_sys{$arg_ref} = $args_ref{$arg_ref};
				   	push(@edit_operations,"insert $arg_ref $args_ref{$arg_ref}");
					if($type eq 'lm'){
						my @temp_sys = extract_content(\%args_sys);
					   	my $sys_lm = $lm->getLM(\@temp_sys);
					   	$sum += ($ref_lm-$sys_lm); 
					}
					 #compute cost
				}elsif(!exists($args_ref{$arg_sys})){ #if the argument of sys is not in ref
					#apply delete of arg and content of sys
					push(@edit_operations,"delete $arg_sys $args_sys{$arg_sys}");
					delete ($args_sys{$arg_sys});
					if($type eq 'lm'){
						my @temp_sys = extract_content(\%args_sys);
					   	my $sys_lm = $lm->getLM(\@temp_sys);
					   	$sum += ($ref_lm-$sys_lm); 
					}
				   	
				}
			}
			
		}		
	}
	foreach my $operation(@edit_operations){
		print $LOG "SEGMENT: $segment\tVERB: $v_sys operation:$operation \n" if ($verbose);	
	}

	my $number_of_edit_operations = scalar(@edit_operations);
	
	if($type eq 'number'){
		if($number_of_edit_operations != 0){
			$sum = 1/$number_of_edit_operations; #inverse of distance when just edit operations without LM
		}else{
			$sum = 1;
		}		
		
	}elsif($type eq 'lm'){
		
		$sum = abs($sum);
		if($sum > 1.0){ #if the sum of diferences is to high
			$sum = $sum -int($sum);
		}
	}
	print $LOG "SEGMENT: $segment\tVERB: $v_sys args_score:$sum \n" if ($verbose);
	return $sum;
}


sub extract_content{
	my ($args) = shift;
	my @sentence = ();

	foreach my $key(keys(%{$args})){
		my @temp_words = ();
		@temp_words = split(/\s+/,$args->{$key});
		foreach my $word(@temp_words){
			push(@sentence,$word);
		}
		
	}
	return @sentence;
}
#####
#in: chunks sys, chunks, ref
#out: fluency score: if the chunk of the sys match the chunk of the ref (in the same order) score 0.5, if the content is the same score 1 
sub chunk_matcher
{
	my ($segment,$sys,$ref) = @_;
	#fisrt extract chunks
	
	#my (%chunks_sys, %chunks_ref)= ();
	my (@chunks_sys, @chunks_ref)= ();	
	#tie %chunks_sys, "Tie::IxHash";
	#first extract words
	my @content_sys;
	my @content_ref;
	#TODO later put option to lemmas
	if($arg_content eq 'word'){
		@content_sys = split(/\s+/,$sys->{'word'});
		@content_ref = split(/\s+/,$ref->{'word'});
	}elsif($arg_content eq 'lemma')
	{
		@content_sys = split(/\s+/,$sys->{'lemma'});
		@content_ref = split(/\s+/,$ref->{'lemma'});
		
	}
	
	my @pos_sys = split(/\s+/,$sys->{'pos'});
	my @pos_ref = split(/\s+/,$ref->{'pos'});

	#second extract srl (srl starts at 0)
	
	my @chunk_sys = split(/\s+/,$sys->{'chunk'});
	my @chunk_ref = split(/\s+/,$ref->{'chunk'});
	
	print $LOG "SEGMENT: $segment\t sys: @chunk_sys ref: @chunk_ref\n" if ($verbose);
	#attach words to chunks
	
	#my $w = 0;
 
	foreach my $i(0..$#chunk_sys){
		if($chunk_sys[$i] !~ m/^O/){ 
			$chunk_sys[$i] =~ m/^\w+-(.*)$/;	#extract chunk
			my $phrase = $1;
			
			if($phrase =~ m/^NP/){
				if($pos_sys[$i] =~ m/N.*/ && ($chunk_sys[$i] =~ m/^(E|S)-.*/)){
					push(@chunks_sys,$content_sys[$i].' '.$phrase);
					#$w++;
				}
				
					
			}else{		
				push(@chunks_sys,$content_sys[$i].' '.$phrase);
				#$w++;
				
			}
		}	
	}
	#$w = 0;
	foreach my $i(0..$#chunk_ref){
		if($chunk_ref[$i] !~ m/^O/){
			$chunk_ref[$i] =~ m/^\w+-(.*)$/;	#extract chunk
			my $phrase = $1;
						
			if($phrase =~ m/^NP/){
				if($pos_ref[$i] =~ m/N.*/ && ($chunk_ref[$i] =~ m/^(E|S)-.*/)){
					push(@chunks_ref,$content_ref[$i].' '.$phrase);
					#$w++;
				}
			}else{		
				push(@chunks_ref,$content_ref[$i].' '.$phrase);
				#$w++;
			} 
		}			
	}
	
	##compare same chunks in order
	my $sum = 0;
	#my $i = 0;	
	foreach my $i(0..$#chunks_sys){
		my $chunk_compare = 0;
		my ($cont_sys,$chunk_sys) = split(/\s+/,$chunks_sys[$i]);
		my ($cont_ref,$chunk_ref) = split(/\s+/,$chunks_ref[$i]);
			if($chunk_sys eq $chunk_ref){
				$chunk_compare += 0.5; 	#if the chunk is the same
				if($cont_sys eq $cont_ref){ #if the content is the same
					$chunk_compare += 0.5;				
				}
				print $LOG "SEGMENT: $segment\tCHUNKS sys: $chunk_sys ->$cont_sys ref: $chunk_ref->$cont_ref score:$chunk_compare \n" if ($verbose);
			}
			
		$sum += $chunk_compare;
		#$i++;
	}

	if(scalar(@chunks_sys) != 0){
		$sum = $sum/scalar(@chunks_sys);
	}else{
		$sum = 0;
	}
	
	return $sum;
	
}

