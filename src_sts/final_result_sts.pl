#!/usr/bin/perl
use strict;

if($#ARGV != 0){
	print "usage:./final_result_sts.pl <file-result>\n";
	exit 1;
}
my $pred = shift;

my $pred_pairs = loadPred($pred);

foreach my $id(sort { $a <=> $b } keys %$pred_pairs){
	my $tmp = []; 
	foreach my $decision(sort {$pred_pairs->{$a} <=> $pred_pairs->{$b}} keys %{$pred_pairs->{$id}}){
			#print "id:$id dec:$decision value:$pred_pairs->{$id}->{$decision}\n";
			my $value = $pred_pairs->{$id}->{$decision};
			push(@$tmp, "$decision:$value");
	}
	
	print "id: $id dv: ",join('/', @$tmp), "\n";
}


sub loadPred
{
	my ($file) = shift;
	open(my $IN, "<", $file) or die "File $file not found\n";
	my $pairs = {};
	while(my $line = <$IN>){
		chomp($line);
		#print "L:$line\n";
		$line =~m/^Sim\(\"(\w+)\",\"(\w+)\"\) (.+)$/;
		my $decision = $1;
		my $id = $2;
		my $prob = $3;
		$pairs->{$id}->{$decision} = $prob;
	}
	return $pairs;
}
