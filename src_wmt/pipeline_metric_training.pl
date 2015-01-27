#!/usr/bin/perl
#use threads;
use strict;

if($#ARGV != 3){
	print "USE: pipeline_metric_training.pl <edit-lm|edit-num|match> <reference> > <dir-systems> <conll-format>\n";
	exit 1;
}
my $type = $ARGV[0];
my $reference = $ARGV[1];
my $system_dir = $ARGV[2];
my $conll = $ARGV[3];
#my $dir = '/tmp';
# 1.- preprocessing
#reference
print "Prepro reference\n";
system("./srl_treetagger_process_training.pl xml $reference");
print "Prepro reference done\n";

my ($DIR,$PRE,$PRO);

opendir($DIR, $system_dir) or die $!;
open($PRE,">","pre.pool")or die $!;
my @thrs;

while (my $file = readdir($DIR)) {
next if ($file =~ m/^\./);
	
	if($file  =~ m/\.xml$/){
		&prePro($file,$system_dir);
	}
	

}

##POOL
system("./pool.sh -p 60 -n 10 -f pre.pool");
sleep(120);
closedir($DIR);
close($PRE);

print "Prepro done\n";

print "Processing...\n";
opendir($DIR, $system_dir) or die $!;
open($PRO,">","pro.pool")or die $!;
my @thrs_metric;

while (my $file = readdir($DIR)) {
next if ($file =~ m/^\./);
	
	if($file  =~ m/\.srl.tt$/){
		&process($reference,$file,$type,$conll,$system_dir);		
		
	}
	

}
close($PRO);
###POOL
if($type =~ m/^edit-/){
	system("./pool.sh -p 540 -n 15 -f pro.pool");
 	system(300);
}elsif($type eq 'match'){
	system("./pool.sh -p 540 -n 15 -f pro.pool");
 	 system(400);
}
#system("./pool.sh -p 540 -n 15 -f pro.pool");
#system(300);
print "finish...";
closedir($DIR);
unlink("pre.pool");
unlink("pro.pool");
#perl -Ireader srl_edit_mt_measure.pl --reference example/newssyscombtest2011-ref.en.sgm.srl.tt --system example/newssyscombtest2011.es-en.alacant.sgm.srl.tt --conll-format conll_config.txt --lang-pair es-en --test-set newssyscombtest --system-id alacant

sub prePro
{
	my($file,$system_dir) = @_;
	 print $PRE "./srl_treetagger_process_training.pl xml $system_dir/$file\n";
}

sub process
{
	my($reference,$file,$type,$conll,$system_dir) = @_;

	my($test_set,$lang_pair,$system_id,@etc) = split(/\./,$file);
	if($type eq 'edit-num'){
		 print $PRO "perl -Ireader srl_edit_mt_measure.pl --reference $reference.srl.tt --system $system_dir/$file --conll-format $conll --lang-pair $lang_pair --test-set $test_set --system-id $system_id --train\n";
	}elsif($type eq 'edit-lm'){
		print $PRO "perl -Ireader srl_edit_mt_measure.pl --reference $reference.srl.tt --system $system_dir/$file --conll-format $conll --lang-pair $lang_pair --test-set $test_set --system-id $system_id --train --edit-eval lm\n";
	}elsif($type eq 'match'){
		 print $PRO "perl -Ireader srl_mt_measure.pl --reference $reference.srl.tt --system $system_dir/$file --conll-format $conll --lang-pair $lang_pair --test-set $test_set --system-id $system_id --train\n";
	}
}


