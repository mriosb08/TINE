#!/usr/bin/perl

use strict;
use BerkeleyDB;
use Getopt::Long "GetOptions";


my ($help, $file, $dbname,$lexiconFile,$relationFile);

$help=1 unless
&GetOptions(
	'file=s' => \$file, 
	'dbname=s' => \$dbname,
	'lexiconFileName=s' => \$lexiconFile,
	'relationsFileName=s' => \$relationFile,
	'help' => \$help
);

if ($help || !$file || !$dbname){
	print "./vo2DB.pl <options>\n\n",
		"\t--file <file>       		the File with the verbOcean data\n",
		"\t--dbname <string>    	name for the output database BTree\n",
		"\t--lexiconFileName <string>   name for the lexicon file (i.e. verb pairs)\n",
		"\t--relationsFileName <string> name for the relations file (i.e. relations between verbs)\n",
		"\t--help               	print these instructions\n\n";
	exit 1;
}
#The file with the lsp format
open(FILE,$file)or die "file:$file not found\n";
#The file with the words in the thesaurus
open(LEX,">",$lexiconFile)or die "could not open file $lexiconFile\n";

open(REL,">",$relationFile)or die "could not open file $relationFile\n";

#open a new BD tree
my $db1 = new BerkeleyDB::Btree(-Filename => "$dbname\.db",-Flags =>DB_CREATE,-Property  => DB_DUP)or die "ERROR: $BerkeleyDB::Error\n";
my @stack=();
my $s=0;
my $word="";
my %lex = ();
my %relations = ();
while(my $line=<FILE>)
{
	if($line !~m/^#/){
		chomp($line);
		my($verb1,$relation,$verb2,$separator,$weight) = split(/\s+/,$line);
		my $key = $verb1.' '.$verb2;
		$relation =~ s/(\[|\])//g;
		my $data = $relation.' '.$weight;
		$db1->db_put($key,$data); #put in the DB
		$lex{$key} = 1;
		$relations{$relation} = 1;
	}
			
}
print LEX "#verb pairs\n";
foreach my $key(sort keys(%lex)){
	print LEX "$key\n";
}

print REL "#Relations between verbs\n";
foreach my $key(sort keys(%relations)){
	print REL "$key\n";
}
close(FILE);
close(LEX);

