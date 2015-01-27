#!/usr/bin/perl
use strict;
use Text::CSV;
use BerkeleyDB;

if($#ARGV != 1){
	print "usage:verbEntialment2db.pl <input-csv> <output-db>\n";
	exit 0;
}

my($input, $output) = (shift, shift);

my $verbs = {};
my $sep = '|||';
$verbs = load_csv($input, $verbs, $sep);
todb($verbs, $output);

sub load_csv
{
	my($file, $verbs, $sep) = @_;
	my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();
 
	open(my $FH, "<:encoding(utf8)", $file) or die "$file: $!";
	while(my $line = <$FH>){
		chomp $line;
		if ($csv->parse($line)){	 
			my ($verb_a, $verb_b, $entailment) = $csv->fields();
			print "$verb_a:$verb_b => $entailment\n";
			my $key = $verb_a.$sep.$verb_b;
			$verbs->{$key} = $entailment;
				
		} else {
			warn "Line could not be parsed: $line\n";
		}
	}

	return $verbs;
}

sub todb
{
	my($verbs, $db) = @_;	
	my $db1 = new BerkeleyDB::Btree(-Filename => $db,-Flags =>DB_CREATE,-Property  => DB_DUP)or die "ERROR: $BerkeleyDB::Error\n";
	foreach my $key(keys %$verbs){
		$db1->db_put($key, $verbs->{$key});
	}
}
