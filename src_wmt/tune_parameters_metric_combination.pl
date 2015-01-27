#!/usr/bin/perl
use AI::Genetic::Pro;



use strict;
if($#ARGV != 3){
	print "USAGE: ./tune_parameters_metric_combination.pl <lang-pair> <metric-a> <metric-b> <human_ranks>\n";
	print "NOTE: format for the metric files..\n test-set system doc-id segment-id score\n";
	exit(1);
}

my $lang_pair = $ARGV[0];
my $metric_a = $ARGV[1];
my $metric_b = $ARGV[2];
my $human_ranks = $ARGV[3];

    
    
    
    my $ga = AI::Genetic::Pro->new(        
        -fitness         => \&fitness,        # fitness function
        -terminate       => \&terminate,      # terminate function
        -type            => 'rangevector',      # type of chromosomes
        -population      => 80,             # population
        -crossover       => 0.9,              # probab. of crossover
        -mutation        => 0.01,             # probab. of mutation
        -parents         => 2,                # number  of parents
        -selection       => [ 'Roulette' ],   # selection strategy
        -strategy        => [ 'Points', 2 ],  # crossover strategy
        -cache           => 0,                # cache results
        -history         => 1,                # remember best results
        -preserve        => 3,                # remember the bests
        -variable_length => 1,                # turn variable length ON
    );
        
  #range vector

	$ga->init([
	[0, 100],
	[0, 100],
	]);
    # evolve 10 generations
    $ga->evolve(100);
    
    # best score
print "IND: ", $ga->as_string($ga->getFittest), "\n";
print "SCORE: ", $ga->as_value($ga->getFittest), "\n";
	


sub fitness {
        my ($ga, $chromosome) = @_;
	my @chromo = $ga->as_array($chromosome);
	my $alpha = $chromo[0]/100;
	my $beta = $chromo[1]/100;
	if($alpha == 0 && $beta == 0){
		return 0;
	}
	#maybe penalize if a+b do not sum 1
	#if($alpha + $beta != 1.0){
	#	return 0;
	#}
	my $out = $lang_pair.'\.'.'metric_a'.'\.'.'metric_b';
	#1 combine
	system("\./combineMetrics.pl $metric_a $alpha $metric_b $beta $out");
	#2 correlation
	system("\./segment_score2rank.pl doc $out > $out\.sort");
	my $result = `\./segment_rank2correlation.pl $lang_pair $human_ranks $out\.sort quiet`;
	my($name,$correlation) = split(/\s+/,$result);
	unlink($out);
	unlink("$out\.sort");
	return $correlation;
}

sub terminate {
	my $result = $ga->getFittest;
	my $correlation = 1;
	return $result >= $correlation ? 1 : 0;
}
    
