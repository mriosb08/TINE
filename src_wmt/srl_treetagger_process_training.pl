#!/usr/bin/perl
use strict;

if($#ARGV != 1){
	print "USE: srl_tagger_process_training.pl <type:plain, xml> <file>\n";
	exit 1;
}
my $senna_path = '/home/tools/senna-v2.0';
my $treetagger_path = '/home/tools/treetagger/2011_jan';
#my $tokenizer_path = '';
my $input = $ARGV[1];
my $type = $ARGV[0];


#print "IN:$input#TY:$type\n";
# extract srl from senna
open(my $TMP,">","$input.tmp")or die "could not create tmp file\n";
open(my $TMP_DOC,">","$input.tmp.doc")or die "could not create tmp_doc file\n";
print STDERR "SENNA->$input.srl\n";
if($type eq 'plain'){

	my $srl_command = "$senna_path/senna-linux64 -path $senna_path/ < $input > $input.srl";
	system("$srl_command 2> $input.senna.log");

}elsif($type eq 'xml'){

	open(my $IN,"<",$input) or die "file $input not found\n";
	my $segment = 0;
	my $doc = 'generic';
	while(my $line = <$IN>){
		chomp($line);
		
		
		if($line =~ m/^<doc docid=\"(.+)\" /){
			$doc = $1;
			$segment = 0;
			#print $TMP_DOC "\n";
		}
		$line =~s/<[^>]*>//g;
		 
		next if($line =~ m/^\s*$/);
		$segment++;
		$line =~ s/&lt;/</g;
		$line =~ s/&gt;/>/g;
		$line =~ s/&apos;/\'/g;
		$line =~ s/&quot;/\"/g;
		$line =~ s/&amp;/\&/g;
		print $TMP "$line\n";
		print $TMP_DOC "$doc#$segment\n";	
		#$line =~s/<\/\w+>//g; #??
	}

	close($TMP);
	close($TMP_DOC);
	close($IN);
	my $srl_command = "$senna_path/senna-linux64 -path $senna_path/ < $input.tmp > $input.srl";
        system("$srl_command 2> $input.senna.log");
}


print STDERR "SENNA done\n";
#tagg with treetagger
print STDERR "treetagger\n";

open($TMP,">","$input.tmp")or die "could not create tmp file\n";

	open(my $IN,"<","$input.srl") or die "file $input not found\n"; #read from srl the tokens
	print "input treetagger: $input.srl\n";
	#print $TMP "<s>\n";
	while(my $line = <$IN>){
		chomp($line);
		#print "$line\n";
		my ($empty,$token,@columns) = split(/\s+/,$line);		
		if($line =~ m/^$/){
			print $TMP "</s>\n\n";
			#print $TMP "<s>\n";
		}
		print $TMP "$token\n";
		#print "$token#@columns\n";
	}

	close($TMP);

	my $treetagger_command = "$treetagger_path/bin/tree-tagger -token -lemma -sgml -eos-tag '</s>' -no-unknown $treetagger_path/params/english-par-linux-3.1.bin < $input.tmp > $input.tt";
        system("$treetagger_command 2> $input.tt.log");

unlink("$input.tmp");
print STDERR "treetagger done\n";

open(my $SRL, "<","$input.srl") or die "file $input.srl not found\n";
open(my $TT, "<","$input.tt") or die "file $input.tt not found\n";
open(my $DOC, "<","$input.tmp.doc") or die "file $input.tmp.doc not found\n";
open(my $OUT,">","$input.srl.tt") or die "could not create file $input.srl.tt\n";

print STDERR "combine srl+treetagger\n";
my @doc_id;
@doc_id = loadDocId(@doc_id);
my $pos_id = 0;
while(my $srl=<$SRL> and my $tt=<$TT>){

	chomp($srl);
	chomp($tt);
	

	my($empty,$word,@columns) = split(/\s+/,$srl);
	my($word_tt,$pos_tt,$lemma_tt) = split(/\s+/,$tt);
	$doc_id[$pos_id] =~ s/#/\t\t/g;
	print $OUT "$doc_id[$pos_id]\t\t$word\t\t$lemma_tt\t\t",join("\t\t",@columns),"\n" if($srl !~ m/^$/);
	if($tt =~ m/<\/s>/){
		print $OUT "\n";
		$pos_id++;
	}
}
print STDERR "combine srl+treetagger done\n";
close($OUT);
close($TT);
close($SRL);
close($DOC);
unlink("$input.tmp.doc");
unlink("$input.srl");
unlink("$input.tt");
unlink("$input.tt.log");
unlink("$input.senna.log");


sub loadDocId
{
	my(@id) = @_;
	open(my $ID, "<","$input.tmp.doc") or die "file $input.tmp.doc not foud  \n";
	while (my $line = <$ID>){
		chomp($line);
		push(@id,$line);
	}
	return @id;
}
