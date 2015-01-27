#!/usr/bin/perl

use strict;

if($#ARGV != 1){
	print "USE: human2system.pl <human_judgments> <system_outputs> > <training-file>\n";
	exit 1;
}
my $human = $ARGV[0];
my $systems = $ARGV[1];

my %ranks = ();
my %sys = ();

my %langs = ('Spanish' => 'es',
		'English' => 'en',
		'Czech' => 'cz',
		'German' => 'de',
		'French' => 'fr',
		);


#load systems output
&loadSystems();

open(my $JU,"<",$human)or die "file $human not found\n";
	my $pos = 0;
	while(my $line = <$JU>){
		chomp($line);
		if($line !~ m/^#/){
			my($srclang,$trglang,$srcIndex,$documentId,$segmentId,$judgeId,$system1Number,$system1Id,$system2Number,$system2Id,$system3Number,$system3Id,$system4Number,$system4Id,$system5Number,$system5Id,$system1rank,$system2rank,$system3rank,$system4rank,$system5rank) = split(/,/,$line);
			my $lang_pair =	$langs{$srclang}.'-'.$langs{$trglang};
			if($langs{$trglang} eq 'en'){
 			
				my($f1,$fr1,$ap1) = split(/\s+/,$sys{$lang_pair}{$system1Id}{$documentId}{$segmentId});
				my($f2,$fr2,$ap2) = split(/\s+/,$sys{$lang_pair}{$system2Id}{$documentId}{$segmentId});
				my($f3,$fr3,$ap3) = split(/\s+/,$sys{$lang_pair}{$system3Id}{$documentId}{$segmentId});
				my($f4,$fr4,$ap4) = split(/\s+/,$sys{$lang_pair}{$system4Id}{$documentId}{$segmentId});
				my($f5,$fr5,$ap5) = split(/\s+/,$sys{$lang_pair}{$system5Id}{$documentId}{$segmentId});

				my @S = ($system1Id, $system2Id, $system3Id, $system4Id, $system5Id);
				my @R = ($system1rank, $system2rank, $system3rank, $system4rank, $system5rank);
				my @F = ($f1, $f2, $f3, $f4, $f5);
				my @FR = ($fr1, $fr2, $fr3, $fr4, $fr5);
				my @AP = ($ap1, $ap2, $ap3, $ap4, $ap5);

				foreach my $a (0 .. $#F -1){
					foreach my $b ($a+1 .. $#F){
						my $label = getLabel($R[$a], $R[$b]);
						print "$label qid:$documentId|||$segmentId 1:",($FR[$a]-$FR[$b])," 2:",($AP[$a]-$AP[$b])," #$S[$a] $S[$b]\n";
					}
				}
			}
				
		}
	
		
	}


sub loadSystems
{
	open(my $SYS,"<",$systems)or die "file $systems not found\n";
	while(my $line = <$SYS>){
		chomp($line);
		if($line !~ m/^#/){
			 my($lang_pair,$test_set,$system_id,$doc_id,$segment_id,$total,$fluency,$fr,$ap) = split(/\s+/,$line);
			
			$sys{$lang_pair}{$system_id}{$doc_id}{$segment_id} = $fluency.' '.$fr.' '.$ap;
			
		}
	
		
	}
}

sub getLabel
{
	my ($A, $B) = @_;
	my $label = ($B - $A);
	$label = 1 if ($label > 0);
	$label = -1 if ($label < 0);
	return $label;
}
