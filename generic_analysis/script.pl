#!/usr/bin/perl -w

use warnings;
use strict;
use autodie;
use Getopt::Std;
use Number::Format  'format_number';
# Overhead Samples  Local Weight  Memory access Symbol Shared Object  Data Symbol Data Object Snoop TLB access Locked
# Overhead sys usr  Local Weight  Memory access Symbol Shared Object  Data Symbol Data Object Snoop TLB access Locked


my $meta_str = '__meta_total';
my %opts = ();

my $__oh = 1;
my $__samples = 2;
my $__weight = 4;
my $__access = 5;
my $__symbol = 6;

my $__total = 0;
my $__cutoff = 1;

getopts('f:', \%opts);

sub usage {
        die "$0 -f <perf repport mem --stdio> \n";
}

usage() unless (defined($opts{'f'}));

open(my $fh, '<', $opts{'f'});

my %symbols = ();
my %accesses = ();
my @events;

push @events, 'Total';

sub show_stats {
	my ($hash, $cutoff) = @_;

	foreach (sort {${$hash}{$b}[$__total] <=> ${$hash}{$a}[$__total]} keys (%{$hash})) {
		if (defined $cutoff) {
			last if (${$hash}{$_}[$__total] < $__cutoff);
		}
		#next unless /mlx5e/;
		my $i = 0;
		printf "%-30s = ", $_;
		foreach my $event (@events) {
			my $orig = ${$hash}{$_}[$i++];
			my $num = defined $orig ? format_number $orig: 0 ;
			$event =~ /cpu\/([\w-]+)/;
			$event = $1 if defined $1;
			printf "%-10s: %-5.2f ", $event, $num;
		}
		printf "\n";
	}
}

sub new_events {
	my $line = shift;
	chomp $line;
	$line =~ /event\s+'(.*)'/;
	die "$line" unless defined $1;
	push @events , $1;
	#printf "NEW $events[$#events]...\n";
}

foreach (<$fh>) {
# Samples: 51K of event 'cpu/mem-loads,ldlat=30/P'
	new_events $_ if /^# Samples/;
	next if /^#/;
	next if /^\s*$/;
	my @line = split /\s{2,}/;
	next unless ($#line > 4);

	chop $line[$__oh];
	$symbols{$line[$__symbol]}[$__total] += $line[$__oh];#$line[$__samples] * $line[$__weight];
	$symbols{$line[$__symbol]}[$#events] += $line[$__oh];#$line[$__samples] * $line[$__weight];

	$accesses{$line[$__access]}[$__total] += $line[$__oh];#$line[$__samples] * $line[$__weight];
	$accesses{$line[$__access]}[$#events] += $line[$__oh];#$line[$__samples] * $line[$__weight];

	#printf "$line[$__symbol] = $line[$__oh]\n";
	#print $_;
	#my $line = join(',',@line);
	#print $line;
	#last;
}
close $fh;

#sub filter {
#	my $hash, $entry = @_;
#}
#$ref = \&subroutine;
#$ref->(@args);

show_stats \%symbols, 1;
show_stats \%accesses;
