#!/usr/bin/perl
use strict;
use Data::Dumper;

if($#ARGV != 1){
	print "usage:rte_eval.pl <pediction-file> <gold-standar>\n";
	print "prediction file alchemy format marginal probs output
			gold standar format id<Tab>decision one per line\n";
	exit 1;
}

my($pred, $gs) = (shift, shift);

my $pred_pairs = loadPred($pred);
my $gs_pairs = loadGs($gs);

my $matrix = ();
$matrix->[0]->[0]=0;
$matrix->[0]->[1]=0;
$matrix->[1]->[0]=0;
$matrix->[1]->[1]=0;

foreach my $id(keys %$gs_pairs){
	if(exists $pred_pairs->{$id}){
		my $final_pred = 'false';
		if($pred_pairs->{$id}->{false} < $pred_pairs->{$id}->{true}){
			$final_pred = 'true';
		}
		my $gs = $gs_pairs->{$id};
		#print STDERR "prob(false):",$pred_pairs->{$id}->{false},"#prob(true):",$pred_pairs->{$id}->{true},"\n";
		#print STDERR "$final_pred#$gs\n";
		if(($final_pred eq 'true') and ($gs eq 'true')){
			$matrix->[0]->[0]++; #true Positive
			
		}elsif(($final_pred eq 'true') and ($gs eq 'false')){
			$matrix->[0]->[1]++; #False Positive
			
		}elsif(($final_pred eq 'false') and ($gs eq 'true')){
			$matrix->[1]->[0]++; #False Negative
			
		}elsif(($final_pred eq 'false') and ($gs eq 'false')){
			$matrix->[1]->[1]++; #True Negative
			
		}
		#print STDERR "$id\t$final_pred\t$gs\n";
	}
}

my $acc = Acc($matrix);
my $precision = Prec($matrix);
my $recall = Rec($matrix);
my $f1 = F1($precision, $recall);
print STDERR "###########################################\n";
print STDERR "#Matrix:\n";
print STDERR "#\tTRUE\t\tFALSE\n";
print STDERR "#TRUE\t$matrix->[0][0]\t\t$matrix->[0][1]\n";
print STDERR "#FALSE\t$matrix->[1][0]\t\t$matrix->[1][1]\n";
print STDERR "###########################################\n";
#printf(STDERR "Accuracy: %.3f\n", $acc);
#printf(STDERR "Precision: %.3f\n", $precision);
#printf(STDERR "Recall: %.3f\n", $recall);
#printf(STDERR "F1: %.3f\n", $f1);
printf("%.3f\t%.3f\t%.3f\t%.3f\n", $acc, $precision, $recall, $f1);



sub Acc
{
	my ($matrix) = shift;
	return 0 if(($matrix->[0]->[0]+$matrix->[0]->[1]+$matrix->[1]->[0]+$matrix->[1]->[1]) == 0);
	my $result = ($matrix->[0]->[0]+$matrix->[1]->[1])/($matrix->[0]->[0]+$matrix->[0]->[1]+$matrix->[1]->[0]+$matrix->[1]->[1]);
	return $result;
}

sub Prec
{
	my ($matrix) = shift;
	return 0 if(($matrix->[0]->[0]+$matrix->[0]->[1]) == 0);
	my $result = $matrix->[0]->[0]/($matrix->[0]->[0]+$matrix->[0]->[1]);  #tp/tp+fp
	return $result;
}

sub Rec
{
	my ($matrix) = shift;
	return 0 if(($matrix->[0]->[0]+$matrix->[1]->[0]) == 0);
	my $result = $matrix->[0]->[0]/($matrix->[0]->[0]+$matrix->[1]->[0]); #tp/tp+fn
	return $result;
}

sub F1
{
	my ($prec, $rec) = @_;
	return 0 if(($prec + $rec) == 0);
	return 0 if(($prec + $rec) == 0);
	my $result = 2 * (($prec * $rec)/($prec + $rec));
	return $result;
}



sub loadPred
{
	my ($file) = shift;
	open(my $IN, "<", $file) or die "File $file not found\n";
	my $pairs = {};
	while(my $line = <$IN>){
		chomp($line);
		#print "L:$line\n";
		$line =~m/^Entailment\(\"(\w+)\",\"(\w+)\"\) (.+)$/;
		my $decision = $1;
		my $id = $2;
		my $prob = $3;
		$pairs->{$id}->{$decision} = $prob;
	}
	return $pairs;
} 

sub loadGs
{
	my ($file) = shift;
	open(my $IN, "<", $file) or die "File $file not found\n";
	my $pairs = {};
	while(my $line = <$IN>){
		chomp($line);
		my($id, $decision) = split(/\s+/, $line);
		$pairs->{$id} = $decision;
	}

	return $pairs;
}
