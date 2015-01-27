#!/usr/bin/perl
use strict;
use XML::Simple;
use Data::Dumper;

if($#ARGV != 2){
	print "use:xml2db_v1.pl <xml-file> <output> [train|test]\n";
	exit 0;
}

my ($file, $output, $in_type) = (shift, shift, shift);

my $xml = new XML::Simple;
my $data = $xml->XMLin($file, KeyAttr => ('id'), ForceArray => 1);
#print Dumper($data);

my $verbs = ();
my $argu = ();
my $mods = ();
my $decisions = ();
my $sep = '|||';

foreach my $pair(keys %{$data->{pair}}){
	print STDERR "ID($pair)\n";
	my $entailment = $data->{pair}->{$pair}->{entailment};
	foreach my $targets(keys %{$data->{pair}->{$pair}->{alignment}->[0]->{v2v}}){
		
		my $t_target = $data->{pair}->{$pair}->{alignment}->[0]->{v2v}->{$targets}->{T}->[0]->{vt}->[0]->{content};
		my $h_target = $data->{pair}->{$pair}->{alignment}->[0]->{v2v}->{$targets}->{T}->[0]->{vh}->[0]->{content};
		
		print STDERR "T:$t_target\tH:$h_target\n";
		$t_target = clean_string($t_target);
		$h_target = clean_string($h_target);
		my $verb_pair;
		foreach my $args(keys %{$data->{pair}->{$pair}->{alignment}->[0]->{v2v}->{$targets}}){
				#print "ARGS:$args\n";
				if($args =~ m/[A-Z]+/ and $args !~ m/T/){
					my $t_arg = $data->{pair}->{$pair}->{alignment}->[0]->{v2v}->{$targets}->{$args}->[0]->{t}->[0];
					my $h_arg = $data->{pair}->{$pair}->{alignment}->[0]->{v2v}->{$targets}->{$args}->[0]->{h}->[0];
					print STDERR "\tARG:$args\n\t\tT:$t_arg\n\t\tH:$h_arg\n";
					$t_arg = clean_string($t_arg);
					$h_arg = clean_string($h_arg);
					$verb_pair = "$pair:$targets";
					my $args_verb = "ArgsMatch(\"$h_arg$sep$t_arg\", \"$args\", \"$verb_pair\")";
					push(@$argu, $args_verb) if($args =~ m/[A-Z]+/);
					#push(@$verbs, "ARGS_$args(\"$h_arg\",\"$t_arg\", \"$pair\")") if($args =~ m/.../); TODO modifiers
				}
		}

		my $verbs_match = "VerbsMatch(\"$h_target$sep$t_target\", \"$verb_pair\", \"$pair\")";
		
		push(@$verbs, $verbs_match);
		
		
	}
	my $entailment_decision = "Entailment($entailment, \"$pair\")";
	push(@$decisions, $entailment_decision);
}
open(my $OUT, ">", $output) or die "file $output not found\n";

print_DB($verbs, $OUT);
#print_DB($argu, $OUT);
print_DB($decisions, $OUT) if($in_type eq 'train');
close($OUT);

sub print_DB
{
	my ($elements, $FILE) = @_;
	foreach my $elem(@$elements){
		print $FILE "$elem\n";
	}
}

sub clean_string
{
	my $string = shift;
	$string =~ s/"/\@Q\@/g;
	return $string;
}

