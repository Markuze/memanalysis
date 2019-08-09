#!/usr/bin/perl -w

use warnings;
use strict;
use autodie;
use Getopt::Std;
use Number::Format  'format_number';

my $time = 15;
my %opts = ();
getopts('f:p:', \%opts);

sub usage {
        die "$0 -f <perf repport --stdio> p <packet count>\n";
}

usage() unless (defined($opts{'f'}));
usage() unless (defined($opts{'p'}));

open(my $fh, '<', $opts{'f'});

my $events;
my $pps = $opts{'p'} * $time;
my $cpp;

sub get_events {
	my $line = shift;
	$line =~ /(\d+)$/;
	$events = $1;
	$cpp = $events/$pps;
	#printf "Events==> ($events)";
}

my $val;
while(<$fh>) {
	get_events $_ if /Event/;
	$val = $1 if /^\s+([\d\.]+)%/;
	if (defined $val) {
		if ($val > 3 or /mlx5/) {
			printf "%.2f",($val * $cpp/100);
			print "$_";
		}
	}
	undef $val;
}

printf "%.2f : cycles per packet\n", $cpp;
