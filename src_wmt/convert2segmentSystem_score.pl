#!/usr/bin/perl

use strict;

if($#ARGV != 2){
	print "USE: convert2segmentSystem_score.pl <doc|no-doc> <dir-scores> <extention> > <output>\n";
	exit 0;
}

my $type = $ARGV[0];
my $dir = $ARGV[1];

my $extention = $ARGV[2];

opendir (my $DIR, $dir) or die "could not open dir$dir\n";
$extention =~ s/\./\\\./g;
while (my $file = readdir($DIR)) {
		#print "$extention # $file\n";
		#next if($file =~ m/^./);
		#print "$extention ### $file\n";		
		if($file =~ m/$extention$/){
			open(my $FILE,"$dir\/$file") or die "file not found $file\n";
			while(my $line = <$FILE>){
				chomp($line);
				if($type eq 'doc'){
					my($name,$lang,$test,$system,$doc,$segment,$score) = split(/\s+/,$line);
					print "$test\t$system\t$doc\t$segment\t$score\n";
				}elsif($type eq 'no-doc'){
					my($name,$lang,$test,$system,$segment,$score) = split(/\s+/,$line);
					print "$test\t$system\t$segment\t$score\n";
				}
				
			}
			close($FILE);
		}
		
}
close($DIR);
