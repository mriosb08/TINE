#!/usr/bin/perl
use strict;

if($#ARGV != 1){
	print "USE: segment_score2rank.pl <doc|no-doc> <file> > <output>\n";
	exit (0);
}
my $type = $ARGV[0];
my $file = $ARGV[1];
my %rank = ();
my %info = ();

#my $t_set;
open(my $FILE,$file) or die $!;
while(my $line = <$FILE>){
	chomp($line);
	if($type eq 'doc'){
		my($test_set,$system,$doc_id,$segment,$score) = split(/\s+/,$line);
		#print STDERR "$system|||$score\n";
		$rank{$doc_id}{$segment} .= $system.'|||'.$score.' ';
		#$t_set = $test_set;
	}elsif($type eq 'no-doc'){
		my($test_set,$system,$segment,$score) = split(/\s+/,$line);
		#print STDERR "$system|||$score\n";
		$rank{$segment} .= $system.'|||'.$score.' ';
	}	
	
}
close($FILE);
	

my %segment_rank = ();

if($type eq 'doc'){
	foreach my $doc_id (keys(%rank)){
	     foreach my $segment(keys(%{$rank{$doc_id}})){
			my @systems = split(/\s+/,$rank{$doc_id}{$segment});
			#print STDERR "$rank{$doc_id}{$segment}\n";
			foreach my $sys(@systems){
				my($system,$score) = split(/\|\|\|/,$sys);
				#print STDERR "$system,$score\n";
				$segment_rank{$system} = $score;					
			}
		
			my @systems_array =();
			foreach my $s(sort {$segment_rank{$a} <=> $segment_rank{$b}} keys %segment_rank){
	     		push(@systems_array,$s.'|||'.$segment_rank{$s});
			}
			%segment_rank = ();
			@systems_array = reverse(@systems_array);
			print "$doc_id $segment ".join(' ',@systems_array)."\n";
		}
		#print "\n";
	}
}elsif($type eq 'no-doc'){
	foreach my $segment(keys(%rank)){
			my @systems = split(/\s+/,$rank{$segment});
			#print STDERR "$rank{$doc_id}{$segment}\n";
			foreach my $sys(@systems){
				my($system,$score) = split(/\|\|\|/,$sys);
				#print STDERR "$system,$score\n";
				$segment_rank{$system} = $score;					
			}
		
			my @systems_array =();
			foreach my $s(sort {$segment_rank{$a} <=> $segment_rank{$b}} keys %segment_rank){
	     		push(@systems_array,$s.'|||'.$segment_rank{$s});
			}
			%segment_rank = ();
			@systems_array = reverse(@systems_array);
			print "$segment ".join(' ',@systems_array)."\n";
		}
}


