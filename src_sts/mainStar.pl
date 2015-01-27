#!/usr/bin/perl
use strict;
use AlignmentPoint;
use HypothesizedAlignment;
use AlignmentFinder;

#[0, 0.041127, 0.019522, 0.013015, 0, 0.058536, 0]
# [0, 0, 0, 0, 0, 0, 0]
#my @matrix = (	[0.618200, 0.246672, 0.408265, 0.213345, 0.083321, 0, 0],
#		[0.246672, 0.646346, 0.420364, 0.220566, 0.083321, 0.030540, 0],
#		[0, 0.041127, 0.019522, 0.013015, 0, 0.058536, 0],
#		[0, 0, 0, 0, 0, 0, 0],
#		);

my @matrix = (	[0.24, 0.02, 0],
		[0, 0.23, 0],
		[0, 0, 0],
		);

my $start = AlignmentPoint->new(key=>'0-0', i=>'0', j=>'0', score=>0.24);
#TODO use just the best as first point
my $solver = AlignmentFinder->new(matrix=>\@matrix, nulli=>2, nullj=>2, criterion=>0.06);
$solver->AStarSolver($start);
my $path = $solver->getPath();
print $path->getpathAsString(), "\n";
print $path->getScore(),"\n";
 
