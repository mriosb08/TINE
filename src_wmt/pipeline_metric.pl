#!/usr/bin/perl
use threads;
use strict;

if($#ARGV != 5){
	print "USE: pipeline_metric.pl <edit-lm|edit-num|match|tine> <reference> > <dir-systems> <conll-format> <alfa> <beta>\n";
	exit 1;
}
my $type = $ARGV[0];
my $reference = $ARGV[1];
my $system_dir = $ARGV[2];
my $conll = $ARGV[3];
my $alfa = $ARGV[4];
my $beta = $ARGV[5];

#my $dir = '/tmp';
# 1.- preprocessing
#reference
print "Prepro reference\n";
#system("./srl_treetagger_process.pl sgml $reference");
print "Prepro reference done\n";

my ($DIR,$PRE,$PRO);

opendir($DIR, $system_dir) or die $!;
open($PRE,">","pre.pool")or die $!;
my @thrs;

while (my $file = readdir($DIR)) {
next if ($file =~ m/^\./);
	
	if($file  =~ m/\.sgm$/){
	#	&prePro($file,$system_dir);
	}
	

}

##POOL
#system("./pool.sh -p 60 -n 10 -f pre.pool");
#sleep(120);
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

if($type eq 'match'){
	system("./pool.sh -p 60 -n 15 -f pro.pool");
	sleep(60);
	
}elsif($type =~ m/^edit/){
	system("./pool.sh -p 60 -n 15 -f pro.pool");
	sleep(60);
}elsif($type eq 'tine'){
	system("./pool.sh -p 60 -n 15 -f pro.pool");
	sleep(60);
}

print "finish...";
closedir($DIR);
unlink("pre.pool");
unlink("pro.pool");
#perl -Ireader srl_edit_mt_measure.pl --reference example/newssyscombtest2011-ref.en.sgm.srl.tt --system example/newssyscombtest2011.es-en.alacant.sgm.srl.tt --conll-format conll_config.txt --lang-pair es-en --test-set newssyscombtest --system-id alacant

sub prePro
{
	my($file,$system_dir) = @_;
	 print $PRE "./srl_treetagger_process.pl sgml $system_dir/$file\n";
}

sub process
{
	my($reference,$file,$type,$conll,$system_dir) = @_;
	print "$file $type\n";
	my($test_set,$lang_pair,$system_id,@etc) = split(/\./,$file);
	if($type eq 'edit-lm'){
		 print $PRO "perl -Ireader srl_edit_mt_measure.pl --reference $reference.srl.tt --system $system_dir/$file --conll-format $conll --lang-pair $lang_pair --test-set $test_set --system-id $system_id --edit-eval lm --back\n";
	}elsif($type eq 'edit-num'){
		#print "num\n";
		 print $PRO "perl -Ireader srl_edit_mt_measure.pl --reference $reference.srl.tt --system $system_dir/$file --conll-format $conll --lang-pair $lang_pair --test-set $test_set --system-id $system_id --back\n";
	}elsif($type eq 'match'){
		 print $PRO "perl -Ireader srl_mt_measure.pl --reference $reference.srl.tt --system $system_dir/$file --conll-format $conll --lang-pair $lang_pair --test-set $test_set --system-id $system_id\n";
	}elsif($type eq 'tine'){
		print $PRO "perl -Ireader tine.pl --reference $reference.srl.tt --system $system_dir/$file --conll-format $conll --lang-pair $lang_pair --test-set $test_set --system-id $system_id\n";
	}
}


