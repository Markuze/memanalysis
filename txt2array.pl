#!/usr/bin/perl -w

use strict;
use autodie;

my $__fm = "mem.txt";

sub txt2arr_line {
	my $line = shift;
	return undef unless $line =~ /^\s+\d/;
	my @line = split /\s{2,}/, $line;
	return (\@line);
}

sub text2arr {
	my $fm = shift;
	my @array = ();

	open (my $fh, "<", $fm);

	while (<$fh>) {
		my $line = txt2arr_line $_;
		push @array, $line if (defined($line));
#		if (defined($line)) {
#			foreach (@{$line}) {
#				chomp;
#				print ("<$_>");
#			}
#			printf "\n";
#		}
#		exit if $#array > 10;
	}
	return \@array;
}

my $arr  = text2arr $__fm;
foreach (@{$arr}) {
	foreach (@{$_}) {
		chomp;
		print ("<$_>");
	}
	printf "\n";
}

