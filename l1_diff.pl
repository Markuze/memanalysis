#!/usr/bin/perl -w

use strict;
use autodie;
use List::Util qw(sum);

my %entry = ();

while (<>) {
	die "wtf? $_" unless /^([\w\s\/\(\)\:]+?):\s+\d/;
#	$entry{"$1"} = undef;
	my $entry = "$1";
	my $i = 0;

	foreach (/\s+(\d+)[\s:]/g) {
		push @{$entry{"$entry"}{'arrays'}{"$i"}}, $_;
		$i++;
	}
}

foreach (keys(%entry)) {

	printf "%80s", $_;
	foreach my $i (sort {$a <=> $b} keys %{$entry{"$_"}{'arrays'}}) {
		my $arr = $entry{"$_"}{'arrays'}{"$i"};
		my $avg = sum(@{$arr})/@{$arr};
		my @l1;
		foreach (@{$arr}) {
			push @l1, abs($avg - $_);
		}
		my $l1 = sum(@l1)/@l1;
		printf ":%9d [%4d]", $avg, $l1;
	}
	printf "\n";
}
