#!/usr/bin/perl -w

use strict;
use autodie;

my $file_1 = 'vanila_l3_1.stats';
my $file_2 = 'damn_l3_1.stats';

open(my $fh_1, '<', $file_1);
open(my $fh_2, '<', $file_2);

my %funcs_1;
my %funcs_2;

while (<$fh_1>) {
	next unless /^[\w\s\(\)]+:\w+\s*:\s+\d+\s+:/;
	my @line = split /:/;
	$funcs_1{$line[1]} += $line[2];
}

close $fh_1;

while (<$fh_2>) {
	next unless /^[\w\s\(\)]+:\w+\s*:\s+\d+\s+:/;
	my @line = split /:/;
	$funcs_2{$line[1]} += $line[2];
}
close $fh_2;

printf "%-40s: %10s : %10s\n", 'function', 'vanila', 'damn';
foreach (sort {$funcs_1{$b} <=> $funcs_1{$a}} keys(%funcs_1)) {
	my $damn = 0;
	$damn = $funcs_2{$_} and delete $funcs_2{$_} if (exists $funcs_2{$_});

	printf "%-40s: %10d : %10d\n", $_, $funcs_1{$_}, $damn;
}
foreach (sort {$funcs_2{$b} <=> $funcs_2{$a}} keys(%funcs_2)) {
	printf "%-40s: %10d : %10d\n", $_, 0, $funcs_2{$_};
}
