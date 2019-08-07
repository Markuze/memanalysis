#!/usr/bin/perl -w

use strict;
use autodie;

my %functions = ();
my %hits = ();
my $t_overhead = 0;
my $t_weight = 0;

sub parse_line {
	my $line = shift;
	my @line = split /\s+/, $line;
	return unless $line =~ /\[k\]\s+(\w+)\s+.*\[k\]\s+0x([0-9a-f]+)\s/;

	my $name = $1;
	printf "$name : $line[1],$line[4]\n";

	$overhead = substr($line[1], 0, -1);
	$weight = int($line[3]);

	$t_overhead += $overhead;
	$t_weight += $weight;
	$functions{$1}{'sample'} += $overhead;
	$functions{$1}{'weight'} += $weight;
	$functions{$1}{'uniq'}++ unless (exists($functions{$1}{'addr'}{$2}));
	$functions{$1}{'addr'}{$2} = undef;
	die "hemmm... $line\n" unless
		($line =~ /\d+\%\s+\d+\%\s+\d+\s+([\w\s\/\(\)]+\w)\s+\[k\]/);
	#$functions{$name}{"$1"}++;
	$hits{"$1"}{'count'} += int($line[2]);
	$hits{"$1"}{'sample'}{$name} += int($line[2]);
	$hits{"$1"}{'weight'}{$name} += int($line[3]);
	$hits{"$1"}{'sample_total'} += int($line[2]);
	$hits{"$1"}{'weight_total'} += int($line[3]);
}

sub drop_stats {

	foreach (sort {$functions{$b}{'weight'} <=> $functions{$a}{'weight'}} keys(%functions)) {
		printf "%-40s: %8d [%3.2f]: %8d[%3.2f]: %8d\n", $_,
			$functions{$_}{'sample'}, (100 * $functions{$_}{'sample'})/$sample,
			$functions{$_}{'weight'}, (100 * $functions{$_}{'weight'})/$weight,
			$functions{$_}{'uniq'};
	}
	printf "\nMemory Hit types...\n";
	my $sample_all = 0;
	my $weight_all = 0;

	foreach my $key (keys(%hits)) {
		$weight_all += $hits{$key}{'weight_total'};
		$sample_all += $hits{$key}{'sample_total'};
	}

	foreach my $key (sort {$hits{$b}{'count'} <=> $hits{$a}{'count'}} keys(%hits)) {
		printf "%-40s : %d [%.2f] impact w: %.2f s: %.2f\n", $key, $hits{$key}{'count'},
						$hits{$key}{'weight_total'}/$hits{$key}{'sample_total'},
						(100 * $hits{$key}{'weight_total'})/$weight_all,
						(100 * $hits{$key}{'sample_total'})/$sample_all;

		foreach (sort{ $hits{$key}{'sample'}{$b} <=> $hits{$key}{'sample'}{$a} } keys ( %{$hits{$key}{'sample'}} )) {
			my $wi = 0;
			$wi = (100 * $hits{$key}{'weight'}{$_})/$hits{$key}{'weight_total'} if ($hits{$key}{'weight_total'} > 0);
			printf "%-40s:%-40s: %8d : %8d [%.2f] w: %.2f s: %.2f\n", $key, $_,
								$hits{$key}{'sample'}{$_}, $hits{$key}{'weight'}{$_},
								$hits{$key}{'weight'}{$_}/$hits{$key}{'sample'}{$_},
								$wi,
								(100 * $hits{$key}{'sample'}{$_})/$hits{$key}{'sample_total'};
		}
	}
}

while (<>) {
	chomp;
	next if /^\#/;
	parse_line($_);
}

drop_stats;
