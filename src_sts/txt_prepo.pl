#!/usr/bin/perl
use XML::XPath;
use XML::XPath::XMLParser;

if($#ARGV != 4){
	print "use: txt_prepro.pl <file> <text-output> <hypo-output> <senna-path> <tree_tagger-path>\n";
	exit 0;
}

my($file, $t_file, $h_file, $senna_path, $treetagger_path, $max) = (shift, shift, shift, shift, shift, shift);


#my $senna_path = '/home/tools/senna-v2.0';
#my $treetagger_path = '/home/tools/treetagger/2011_jan';
#my @meta = ();
my @T = ();
my @H = ();

open(my $FILE, "<", $file) or die "file $file not found\n";
#open(my $SCORE, "<", $score) or die "file $score not found\n";

while(my $line = <$FILE>){
	chomp($line);
	next if $line =~ m/^\s*$/;
	
	my($t, $h) = split(/\t/, $line);
	
	push(@T, $t);
	push(@H, $h);
}

close($FILE);

#while(my $line = <$SCORE>){
#	chomp($line);
#	next if $line =~ m/^\s*$/;
	
#	$line =~ m/id=\"(.+)\"\svalue=\"(.+)\"\stask=\"(.+)\"/;
#	my $id = $1;
#	my $value = $2;
#	my $task = $3;
	
#	push(@meta, "$id\t$value\t$task");
#}

#	

print "PREPOSTART\n";
#my @meta_tmp = @meta;
&prepro_srl_tt($file.'.text', $t_file, \@T, $senna_path, $treetagger_path);
&prepro_srl_tt($file.'.hypo', $h_file,\@H, $senna_path, $treetagger_path);
	


sub prepro_srl_tt
{
	my ($file, $output,$lines, $senna_path, $treetagger_path) = @_;
	
	#write to file
	open(my $FILE, ">","$file")  or die "file $file not found\n";
	foreach $line (@{$lines}){
		print $FILE $line,"\n";
	}
	close($file);

	my $srl_command = "$senna_path/senna-linux64 -path $senna_path/ < $file > $file\.srl";
	system("$srl_command");

	#print "CMMD:$srl_command\n";
	open(my $IN,"<","$file.srl") or die "file $file not found\n"; #read from srl the tokens

	open(my $TMP,">","tmp")or die "could not create tmp file\n";

	while(my $line = <$IN>){
		chomp($line);
		#print "$line\n";
		$line =~ s/^\s+//;
		my ($token,@columns) = split(/\s+/,$line);		
		if($line =~ m/^$/){
			print $TMP "</s>\n\n";
			#print $TMP "<s>\n";
		}
		print $TMP "$token\n";
		#print "$token#@columns\n";
	}

	#

	close($TMP);

	my $treetagger_command = "$treetagger_path/bin/tree-tagger -token -lemma -sgml -eos-tag '</s>' -no-unknown $treetagger_path/params/english.par < tmp > $file\.tt";
	system("$treetagger_command");

	unlink("tmp");


	open(my $SRL, "<","$file\.srl") or die "file $file.srl not found\n";
	open(my $TT, "<","$file\.tt") or die "file $file.tt not found\n";
	open(my $OUT,">","$output") or die "could not create file $output\n";


	#my $pos_id = 0;
	#$meta_tag = shift(@{$array_meta});
	#print "META:$meta_tag\n";
	$i = 0;
	while(my $srl=<$SRL> and my $tt=<$TT>){

		chomp($srl);
		chomp($tt);
	
		$srl =~ s/^\s+//;
		my($word,@columns) = split(/\s+/,$srl);
		my($word_tt,$pos_tt,$lemma_tt) = split(/\s+/,$tt);
		print $OUT "$i\t$word\t$lemma_tt\t",join("\t",@columns),"\n" if($srl !~ m/^$/);
		
		if($tt =~ m/<\/s>/){
			print $OUT "\n";
			$i++;
			#$pos_id++;
			#$meta_tag = shift(@{$array_meta});
			#print "META: $meta_tag\n";
		}
	}

	close($OUT);
	close($TT);
	close($SRL);
	unlink("$file");
	unlink("$file.srl");
	unlink("$file.tt");
	#unlink("$file.srl.tt");
	
}
