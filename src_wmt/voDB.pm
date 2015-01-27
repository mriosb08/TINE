package voDB;
use BerkeleyDB;
use strict;
use warnings;

####
my $conection_database;
my @relations = ('can-result-in',
		'happens-before',
		'low-vol',
		'opposite-of',
		'similar',
		'stronger-than',
		'unk',
		);
####
sub new 
{
	my $class = shift;
	my $voDB = {@_};

	$voDB->{database}||= 'data/verbocean.db';
	$voDB->{v_a}||= undef;
	$voDB->{v_b}||= undef;
	$voDB->{relation}||= undef;
	if($voDB->{database} =~ m/\.db$/)
	{
		$voDB->{database} = $voDB->{database}
	}else{
		$voDB->{database} = $voDB->{database}."\.db";
	}
	$conection_database = new BerkeleyDB::Btree(-Filename => "$voDB->{database}",-Flags =>DB_RDONLY)or die "Error db: $voDB->{database} not found\n";

    bless $voDB,$class;
    return $voDB;
}
###SET###
#Input: verb a, verb b (lemmas) 
#
sub setVerbs
{
	my $voDB = shift;
	my ($a,$b) = @_;
	$voDB->{v_a} = $a if defined($a);
	$voDB->{v_b} = $b if defined($b);
	
}
###GET###
# Input: -, the set verbs 
# output: realtion between verbs
#
sub getRelation
{
	my $voDB = shift;
	my $key = $voDB->{v_a}.' '.$voDB->{v_b};

	my $tempdata;	
	my $relation = "";
	if($conection_database->db_get($key,$tempdata) != 0)
	{	
		
		$relation = 'unk'; #also missing verbs have an unk tag	
	}else
	{
		$tempdata =~ m/^(\w+) .*$/g;
		$relation = $1;	
		
	}

	$voDB->{relation} = $relation;
	return $relation;
}
###
#Input: -, the relation between the set verbs
#output: 
sub getVector
{
	my $voDB = shift;
	my @vector = ();
	foreach my $rel(@relations){
		if($voDB->{relation} eq $rel){
			push(@vector,1);
		}else{
			push(@vector,0);
		}		
	}
	return @vector;
}
####
#TODO extract MORE Verbnet infromation from the set verbs 
1;
