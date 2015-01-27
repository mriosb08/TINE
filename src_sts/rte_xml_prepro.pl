#!/usr/bin/perl
use XML::XPath;
use XML::XPath::XMLParser;

if($#ARGV != 4){
	print "use: rte_xml_prepro.pl <file> <text-output> <hypo-output> <senna-path> <tree_tagger-path>\n";
	exit 0;
}

my($file, $t_file, $h_file, $senna_path, $treetagger_path, $max) = (shift, shift, shift, shift, shift);

my $xp = XML::XPath->new(filename => $file);
#my $senna_path = '/home/tools/senna-v2.0';
#my $treetagger_path = '/home/tools/treetagger/2011_jan';
my @meta = ();
my @T = ();
my @H = ();

my $pairs = $xp->find('/entailment-corpus/pair');
#my $i = 0;
foreach my $pair($pairs->get_nodelist){
	my $id = $pair->getAttribute('id');
	my $value = $pair->getAttribute('entailment');
	
	if($value eq 'TRUE'){
		$value = 1;
	}else{
		$value = 0;
	}

	my $task = $pair->getAttribute('task');
	#print "$id\t$value\t$task\n";
	push(@meta, "$id\t$value\t$task");
	#print "ID:$id\n";
	my $hypos = $xp->find("/entailment-corpus/pair[\@id='$id']/h"); # find all paragraphs

	foreach my $hypo ($hypos->get_nodelist) {
		push(@H, $hypo->string_value);
		#print $hypo->string_value, "\n";		    
	}

	my $texts = $xp->find("/entailment-corpus/pair[\@id='$id']/t"); # find all paragraphs

	foreach my $text ($texts->get_nodelist) {
		push(@T, $text->string_value);
		#print $text->string_value, "\n";    
	}
#	$i++;
#	if($i >= $max){
#		print "MAX:$max pairs reached\n";
#		last;
#	}
	
}

print "PREPOSTART\n";
my @meta_tmp = @meta;
&prepro_srl_tt($file.'.text', $t_file, \@T,\@meta, $senna_path, $treetagger_path);
&prepro_srl_tt($file.'.hypo', $h_file,\@H,\@meta_tmp, $senna_path, $treetagger_path);
	


sub prepro_srl_tt
{
	my ($file, $output,$lines, $array_meta, $senna_path, $treetagger_path) = @_;
	
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
	my $meta_tag = shift(@{$array_meta});
	#print "META:$meta_tag\n";
	while(my $srl=<$SRL> and my $tt=<$TT>){

		chomp($srl);
		chomp($tt);
	
		$srl =~ s/^\s+//;
		my($word,@columns) = split(/\s+/,$srl);
		my($word_tt,$pos_tt,$lemma_tt) = split(/\s+/,$tt);
		print $OUT "$meta_tag\t$word\t$lemma_tt\t",join("\t",@columns),"\n" if($srl !~ m/^$/);
		if($tt =~ m/<\/s>/){
			print $OUT "\n";
			#$pos_id++;
			$meta_tag = shift(@{$array_meta});
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
