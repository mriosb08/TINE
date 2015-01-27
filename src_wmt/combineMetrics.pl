#!/usr/bin/perl

use strict;
if($#ARGV != 4){
	print "USAGE: ./combineMetrics.pl <metric-a> <alpha> <metric-b> <beta> <output>\n";
	print "NOTE: format for the metric files..\n test-set system doc-id segment-id score\n";
	exit(1);
}

my $metric_a = $ARGV[0];
my $alpha = $ARGV[1];
my $metric_b = $ARGV[2];
my $beta = $ARGV[3];
my $out = $ARGV[4];


my %scores_a = ();
my %scores_b = ();
my $set;

&load_metric($metric_a,\%scores_a);
&load_metric($metric_b,\%scores_b);

my $combined_score = 0;
my $segment = 0;

open(my $OUT,">",$out)or die "couldnt create $out\n";
# open(my $OUT,">",$out)or die "couldnt create $out\n";

foreach my $sys(keys %scores_a){
	next if($sys eq '_ref'); #skip reference
	foreach my $doc(keys %{$scores_a{$sys}}){
		foreach my $seg(keys %{$scores_a{$sys}{$doc}}){
			my $score_a = $scores_a{$sys}{$doc}{$seg};
			my $score_b = 0;			
			if(exists $scores_b{$sys}{$doc}{$seg}){
				$score_b = $scores_b{$sys}{$doc}{$seg};	
			}
			my $combined_score = (($alpha*$score_a)+($beta*$score_b))/($alpha+$beta);
			print $OUT "$set\t$sys\t$doc\t$seg\t$combined_score\n";		
			$segment++;
		}
	}
}

sub load_metric
{
	my($file,$hash) = @_;
	open(my $IN, $file) or die "could not opne file $file\n";
	while(my $line = <$IN>){
		chomp($line);		
		next if($line =~ m/^#/);		
		my ($test,$sys,$doc,$seg,$score) = split(/\s+/,$line);
		$set = $test;		
		$hash->{$sys}->{$doc}->{$seg} = $score;
	}
}
