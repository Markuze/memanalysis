#!/usr/bin/perl -w

use warnings;
use strict;
use autodie;
use Getopt::Std;
#use Number::Format  'format_number';
# Overhead Samples  Local Weight  Memory access Symbol Shared Object  Data Symbol Data Object Snoop TLB access Locked

my $meta_str = '__meta_total';
my %opts = ();

my $__oh = 1;
my $__samples = 2;
my $__access = 4;
my $__symbol = 5;

getopts('f:', \%opts);

sub usage {
        die "$0 -f <perf repport mem --stdio> \n";
}

usage() unless (defined($opts{'f'}));

open(my $fh, '<', $opts{'f'});

my %symbols = ();
my $events;

sub show_stats {
	my $symbols = shift;
	printf "====$events====\n";
	foreach (sort {${$symbols}{$b} <=> ${$symbols}{$a}} keys (%{$symbols})) {
		printf "$_ = ${$symbols}{$_}\n";
	}
	%symbols = ();
}

sub dump_stats {
	my ($line, $symbols) = @_;
	show_stats $symbols if defined $events;
	chomp $line;
	$events = $line;
	printf "NEW $events...\n";
}

foreach (<$fh>) {
# Samples: 51K of event 'cpu/mem-loads,ldlat=30/P'
	dump_stats $_, \%symbols if /^# Samples/;
	next if /^#/;
	next if /^\s*$/;
	my @line = split /\s{2,}/;
	die "$_" unless ($#line > 0);

	chop $line[$__oh];
	$symbols{$line[$__symbol]} += $line[$__samples];

	#printf "$line[$__symbol] = $line[$__oh]\n";
	#print $_;
	#my $line = join(',',@line);
	#print $line;
	#last;
}
close $fh;

show_stats \%symbols;
