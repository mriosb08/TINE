#!/usr/bin/perl

use strict;

if(@ARGV < 3){
	print "USE: segment_rank2correlation.pl <lang-pair> <human_ranks> <segment_ranks> [quiet]\n";
	print "format segment_ranks:\n doc_id segment_id system_rank_1|||score system_rank_2|||score system_rank_3|||score...\n";
	exit 1;
}
my ($segment_srclang,$segment_trglang) = split(/\-/,$ARGV[0]);
my $human = $ARGV[1];
my $segments = $ARGV[2];
my $quiet = 0;
$quiet = 1 if (@ARGV == 4 and $ARGV[3] eq 'quiet');

my %ranks = ();
my %seg = ();

my %langs = ('Spanish' => 'es',
		'English' => 'en',
		'Czech' => 'cz',
		'German' => 'de',
		'French' => 'fr',
		);


#load segments output
&loadSegments();

open(my $JU,"<",$human)or die "file $human not found\n";
my $concordant = 0;
my $discordant = 0;
my $n = 0;
my $cz = 1;
my $ties = 0;
my $system_ties = 0;
while(my $line = <$JU>){
	chomp($line);
	if($line !~ m/^#/){
		my($srclang,$trglang,$srcIndex,$documentId,$segmentId,$judgeId,$system1Number,$system1Id,$system2Number,$system2Id,$system3Number,$system3Id,$system4Number,$system4Id,$system5Number,$system5Id,$system1rank,$system2rank,$system3rank,$system4rank,$system5rank) = split(/\,/,$line);
		#my $lang_pair =	$langs{$srclang}.'-'.$langs{$trglang};
		if(($langs{$trglang} eq $segment_trglang) and ($langs{$srclang} eq $segment_srclang)){
			
			if(exists($seg{$documentId}{$segmentId})){
				my $systems = $seg{$documentId}{$segmentId};
			
			
				my @S = ($system1Id, $system2Id, $system3Id, $system4Id, $system5Id);
				my @R = ($system1rank, $system2rank, $system3rank, $system4rank, $system5rank);
				
				foreach my $i (0 .. ($#R -1)){
					foreach my $j($i+1..$#R){
						my $is_concordunt = isConc($R[$i],$S[$i],$R[$j],$S[$j],$systems);
						if($is_concordunt == 1){
							$concordant++;
							$n++;  #do not count ties
						}elsif($is_concordunt == -1){
							$discordant++;
							$n++;
						}elsif($is_concordunt == 0){
							$ties++;
						}
						$cz++;
					}
					
				}
				
			}				
			
		}
			
	}

	
}

my $tau = ($concordant - $discordant)/$n;
#print "T: $tau\t C:$concordant D:$discordant N:$n\n";
$tau = sprintf("%.2f", $tau);
if ($quiet){
	print "$segments $tau\n";
} else{
	print "CONCORDANT:$concordant\nDISCORDANT:$discordant\nTIES:$ties\nSYTEM_TIES:$system_ties\nTOTAL:$cz\nN:$n \nTAU:$tau \n";
}

sub loadSegments
{
	open(my $SEG,"<",$segments)or die "file $segments not found\n";
	while(my $line = <$SEG>){
		chomp($line);
		if($line !~ m/^#/){
			 my($doc_id,$segment_id,@systems) = split(/\s+/,$line);
			#print "@systems\n";
			$seg{$doc_id}{$segment_id} = [@systems];
			
		}
	
		
	}
}

sub isConc
{
	my($first_rank,$first_id,$second_rank,$second_id,$systems) = @_;
	my $result = 0;
	#first is better than second
	my ($first_sys_rank,$second_sys_rank);
	
	if($first_id =~m/^_ref/ or $second_id =~ m/^_ref/){
		return 'r';		
	}

	if($first_rank == $second_rank){
		#print "\% $first_rank # $first_id # $second_rank # $second_id \n";
		return 0;
	}else{
		my $tie_flag = 0;
		my $score_first = 0;
		my $score_second = 0;
		foreach my $i(0..$#{$systems}){
			my ($system,$score) = split(/\|\|\|/,$systems->[$i]);
			#print "S:$system,$score $first_id,$second_id\n";
			if($system eq $first_id){
				$first_sys_rank = $i;
				$score_first = $score;
			}

			if($system eq $second_id){
				$second_sys_rank = $i;
				$score_second = $score;
			}
		}
		
		if($score_first == $score_second){
			$tie_flag = 1;
			$system_ties++;
		}

		#print "S:$score_first,$score_second, $first_id,$second_id\n";
		#print STDERR "\% $first_rank=$first_id # $second_rank=$second_id # $first_sys_rank=$systems->[$first_sys_rank] # $second_sys_rank=$systems->[$second_sys_rank]\n";

		my $order_human = $second_rank - $first_rank;
		my $order_system = $second_sys_rank - $first_sys_rank;

		#print STDERR "$order_human @ $order_system\n";
		$order_human = 1 if($order_human > 0);
		$order_human = -1 if($order_human < 0);

		$order_system = 1 if($order_system > 0);
		$order_system = -1 if($order_system < 0);
	
		$result = 1 if($order_system == $order_human);
		$result = -1 if($order_system != $order_human);
		$result = -1 if($tie_flag == 1);
		return $result;
	}
	
	
}
