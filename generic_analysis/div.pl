#!/usr/bin/perl -w

use warnings;
use strict;
use autodie;
use Getopt::Std;
use Number::Format  'format_number';


my @a = ();

while (<>) {
	/(\d+)/;
	printf "$1\n";
	push @a, $1;
}

my $idx = $a[1] > $a[0] ? 1 : 0;
printf "$a[1]/$a[0] = %f.2\n", $a[$idx]/$a[1 - $idx];
