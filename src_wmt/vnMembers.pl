#!/usr/bin/perl

use strict;

use DBI;
my $database = 'wordnet30';
my $user = 'root';
my $pass = 'root';

my $conection_database = DBI->connect("DBI:mysql:database=$database;host=localhost",
						"$user",
						"$pass",
						{'RaiseError' => 1});

my $query = "SELECT lemma,COUNT(classid) N,GROUP_CONCAT(class SEPARATOR ' ') AS vnclass FROM vnclassmembers INNER JOIN vnclasses USING (classid) INNER JOIN words USING (wordid) GROUP BY wordid ORDER BY N";
my $command_database = $conection_database->prepare($query);
my %stats = ();

$command_database->execute();
#All verbs
open(OUT, ">verbnetMembers.txt") or die "could not create file\n";
print OUT "#verb vnclass1 vnclass2...\n";
#One class verbs
open(OUTUN, ">verbnetUnAmbiguous.txt") or die "could not create file\n";
print OUTUN "#Verbs which belong to one class\n";
print OUTUN "#verb vnclass\n";
#Ambiguous verbs
open(OUTAM, ">verbnetAmbiguous.txt") or die "could not create file\n";
print OUTAM "#Verbs which belong to more than one class\n";
print OUTAM "#verb vnclass1 vnclass2...\n";

while (my $feched_row = $command_database->fetchrow_hashref()) {
	
	my @classes = split(/\s/,$feched_row->{vnclass});
	my $vnclases = "";
	$stats{$feched_row->{N}}++;
	
	foreach my $class(@classes){
		#my $offset = index("-",$class);
		#$vnclases .= 'VN='.substr($class,$offset).' ';
		$class =~ m/^[a-zA-Z_]+-(.*)$/g;
		my $num = $1;
		$vnclases .= 'VN='.$num.' ';
		#print "$class $num $vnclases\n";
	}
	$feched_row->{lemma} =~ s/\s+/_/g;
	
	print OUT "$feched_row->{lemma} $vnclases\n";

	if(scalar(@classes)>1){
		print OUTAM "$feched_row->{lemma} $vnclases\n";
	}else{
		print OUTUN "$feched_row->{lemma} $vnclases\n";
	}
			
}
print "STATS:\n";
foreach my $key(sort { $a <=> $b } keys(%stats)){
	print "NUM_OF_VERBS:$stats{$key} NUM_OF_CLASSES:$key\n";
}
close(OUT);
close(OUTUN);
close(OUTAM);
