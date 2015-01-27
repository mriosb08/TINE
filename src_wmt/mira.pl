#!/usr/bin/perl

use strict;
use List::Util 'shuffle';

if (@ARGV < 3){
	print STDERR "Usage: mira.pl model input iterations using

	Passive-agressive online learning classifier (Crammer, 2006)
		model: model parameters
		input: instance vectors
		iterations: number of iterations
		using: features currently in use (separated by ',' or '_')

		Samples are shuffled every iteration
	
	The output model: model.out

	\n";
	exit 1;
}

my ($model, $input, $N, $fUsing) = (shift, shift, shift, shift);

my @using = sort{$a <=> $b} split(/[,_]/, $fUsing);

my @w;
my @v;
my $n = 0;

open (my $M, $model);
while (my $line = <$M>){
	chomp($line);
	$line =~ s/#.*//;
	next if $line =~ m/^\s*$/;
	@w = split(/\s+/, $line);
}
close($M);
if (@using){
	print STDERR "# Using features: {" . join (',', @using) . "}\n";
} else{
	print STDERR "# Using all the fatures in the model\n";
	push(@using, $_) foreach (0 .. $#w);
}
push(@v, 0) foreach (@w);
print STDERR "@w" . " # w0\n";

open(my $OUT, ">", "$model.out");

my @instances;

open (my $IN, $input) or die "Could not open input file $input\n";
while (my $line = <$IN>){
	chomp($line);
	$line =~ s/#.*$//;
	$line =~ s/[a-z0-9]+://g;
	push(@instances, $line);
}
close($IN);
print STDERR "# " . scalar(@instances) . " instances loaded\n";

my $n = 0;
my @previous = @w;
my $bestit = 0;
my @best = @w;
my $least = undef;
foreach my $it (1 .. $N){
	open(my $IN, $input) or die "Could not open input file $input\n";
#	while(my $line = <$IN>){
	@instances = shuffle(@instances);
	my $misspredictions = 0;
	my $corrections = 0;
	foreach my $line (@instances){
#		chomp($line);
#		$line =~ s/#.*$//;
#		$line =~ s/[a-z0-9]+://g;
		my ($label, $id, @features) = split(/\s+/, $line);
		next unless $label; # never compares if the difference is zero
		my $prediction = predict(\@w, \@features);
		$misspredictions++ if ($label != $prediction);
		update($prediction, $label,\@features);
		my $newprediction = predict(\@w, \@features);
		if ($newprediction == $label){
			$v[$_] += $w[$_] foreach (@using);
			$n++;
			$corrections++ if ($prediction != $newprediction);
		}
	}
	$v[$_] /= $n foreach (@using);
	@w = @v;
	$n = 0;
	my $d = distance(\@previous, \@w);
	@previous = @w;
	$least = $misspredictions unless defined $least;
	if ($misspredictions < $least){
		$least = $misspredictions;
		$bestit = $it;
		@best = @w;
	}
	print STDERR "@w" . " # w$it d=$d miss=$misspredictions corrections=$corrections\n";
	print $OUT "@w" . " # w$it d=$d miss=$misspredictions corrections=$corrections\n";
	close($IN);
#	last if $d < 0.001;
}
close($OUT);
print STDERR "# {" . join(',', @using) . "} final " . "@w\n";
print STDERR "@best" . " # best=$bestit (miss=$least)\n";

sub predict
{
	my ($w, $f) = @_;
	my $dot = dotproduct($w, $f);
	my $prediction;
	if ($dot > 0){
		$prediction = 1;
	} elsif ($dot == 0){
		$prediction = 0;
	} else{
		$prediction = -1;
	}
	return $prediction;
}

sub distance
{
	my ($old, $new) = @_;
	my $d = 0;
	foreach my $i (@using){
		$d = ($old->[$i]-$new->[$i]) ** 2;
	}
	return sqrt($d);
}

sub update
{
	my ($prediction, $label, $f) = @_; # z is the correct
	if ($prediction and ($prediction != $label) and nonzero($f)){
		my @g;
		push(@g, ($label-$prediction)*$_) foreach (@$f);
		my $tau = (loss($prediction, $label) - dotproduct(\@w, \@g))/dotproduct(\@g, \@g);
		$w[$_] += $tau*$g[$_] foreach (@using);
	}
}

sub loss
{
	my ($prediction, $label) = @_;
	if ($prediction eq $label){
		return 0;
	} else{
		return 1;
	}
}

sub nonzero
{
	my $v = shift;
	foreach my $i (@using){
		if ($v->[$i]){
			return 1;
		}
	}
	return 0;
}

sub dotproduct
{
	my ($a, $b) = @_;
	die "Vectors must be of the same order: " . join(',', @using) . "\n"  if ($#{$a} != $#{$b});
	my $dot = 0;
	foreach my $i (@using){
		$dot += $a->[$i] * $b->[$i];
	}
	return $dot;
}
