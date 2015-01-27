#!/usr/bin/perl
use List::Util 'shuffle';

use strict;

if($#ARGV != 4){
	print "USE: combineAll_segment.pl <doc|no-doc> <dir-scores> <extention> <output-train> <output-test>\n";
	exit 0;
}

my $type = $ARGV[0];
my $dir = $ARGV[1]; 
my $extention = $ARGV[2];
my $out_train = $ARGV[3];
my $out_test = $ARGV[4];

my @s_dir = <$dir/*\.$extention>;
@s_dir = shuffle(@s_dir);

my $size = scalar(@s_dir);

my $training_size = int((90*$size)/100);
my (@test,@train);
print "S:$size TS:$training_size\n";
foreach my $i(0..$training_size-1){
	push(@train,$s_dir[$i]);
}
foreach my $i($training_size..$#s_dir){
	push(@test,$s_dir[$i]);
}
 
open(my $TRAIN,">",$out_train) or die "file not foud $out_train\n";
open(my $TEST,">",$out_test) or die "file not foud $out_test\n";

$extention =~ s/\./\\\./g;
foreach my $file (@test) {
		#print "$extention # $file\n";
		#next if($file =~ m/^./);
		#print "$extention ### $file\n";		
		if($file =~ m/$extention$/){
			open(my $FILE,"$file") or die "file test not found $file\n";
			while(my $line = <$FILE>){
				chomp($line);
				if($type eq 'doc'){
					my($name,$lang,$test,$system,$doc,$segment,$score,$f,$fr,$ap) = split(/\s+/,$line);
					print $TEST "$lang\t$test\t$system\t$doc\t$segment\t$score\t$f\t$fr\t$ap\n";
				}elsif($type eq 'no-doc'){
					my($name,$lang,$test,$system,$segment,$score) = split(/\s+/,$line);
					print $TEST "$lang\t$test\t$system\t$segment\t$score\n";
				}
				
			}
			close($FILE);
		}
		
}

foreach my $file (@train) {
		#print "$extention # $file\n";
		#next if($file =~ m/^./);
		#print "$extention ### $file\n";		
		if($file =~ m/$extention$/){
			open(my $FILE,"$file") or die "file train not found $file\n";
			while(my $line = <$FILE>){
				chomp($line);
				if($type eq 'doc'){
					my($name,$lang,$test,$system,$doc,$segment,$score,$f,$fr,$ap) = split(/\s+/,$line);
					print $TRAIN "$lang\t$test\t$system\t$doc\t$segment\t$score\t$f\t$fr\t$ap\n";
				}elsif($type eq 'no-doc'){
					my($name,$lang,$test,$system,$segment,$score) = split(/\s+/,$line);
					print $TRAIN "$lang\t$test\t$system\t$segment\t$score\n";
				}
				
			}
			close($FILE);
		}
		
}
#close($DIR);
