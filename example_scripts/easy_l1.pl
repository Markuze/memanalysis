#!/usr/bin/perl -w

use strict;
use autodie;
use List::Util qw(sum);

my @nums = ();

while (<>) {
	chomp;
	push @nums, $_;
}

my $avg = sum(@nums)/@nums;
my @l1;
foreach (@nums) {
	push @l1, abs($_ - $avg);
}

my $l1 = sum(@l1)/@l1;

printf "AVG: $avg L1: $l1 (%.5f\%)[%d]\n", (100 * $l1)/$avg, $#l1 + 1;
