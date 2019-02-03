#!/usr/bin/perl -w

use strict;
use autodie;

my $meta_str = '__meta_total';

my $__fm = "mem.txt";
my $event = "";

sub cputxt2arr {

}

sub mem_arrline2hash {
	# Overhead (1):sys (2):usr (3):Local Weight (4):Memory access (5):Symbol (6):Shared Object (7):Data Symbol (8):Data Object (9):Snoop (10):TLB access (11):Locked (12)
		my $line = shift;
		my $hash = shift;
		#key
		my $event 	= ${$line}[0];
		my $symbol 	= ${$line}[6];
		my $access 	= ${$line}[5];

		#value
		my $oh 		= ${$line}[1];
		my $weight 	= ${$line}[4];
		chop $oh;

		#printf "$event: $symbol: $access > $oh: $weight\n";
		${$hash}{$symbol}{$event}{$access}[0] += $oh;
		${$hash}{$symbol}{$event}{$access}[1] += $weight;
		${$hash}{$symbol}{$event}{$access}[2] ++; #count

		${$hash}{$symbol}{$meta_str}[0] += $oh;
		${$hash}{$symbol}{$meta_str}[1] += $weight;
		${$hash}{$symbol}{$meta_str}[2] ++;

		## Need same structure, as not to break sort
		${$hash}{$meta_str}{$meta_str}[0] += $oh;
		${$hash}{$meta_str}{$meta_str}[1] += $weight;
		${$hash}{$meta_str}{$meta_str}[2] ++;

}

sub arr2hash {
	my $arr = shift;
	my $hash = shift;
	my %hash = (); #TODO: Add option to receive hash from the outside.

	$hash = \%hash unless (defined $hash);

	foreach (@{$arr}) {
		mem_arrline2hash $_, $hash;
	}
	return $hash;
}

sub txt2arr_line {
	my $line = shift;

	#Get CPU event: line example: # Samples: 677K of event 'cpu/mem-loads/p'
	if ($line =~ /# Samples/) {
		$line =~ /Samples:\s+([\d+\w]+).*\s(\S+)\s*$/;
		#printf "$1 > $2";
		$event = $2;
		return undef;
	}
	if ($line =~ /# Event count/) {
		$line =~ /\s(\d+)$/;
		$event = $1 if defined ($1);
	}
	# Get Key:
	if ($line =~ /# Overhead/) {
		chomp $line;
		my @line = split /\s{2,}/, $line;
		my $i = 1;
		foreach (@line) {
			printf ":$_ ($i)";
			$i++;
		}
		printf "\n";
		return undef;
	}

	return undef unless $line =~ /^\s+\d/;

	# split line to array; on 2 spaces or more, some strings have one space.
	my @line = split /\s{2,}/, $line;
	return undef unless defined $line[6];

	#post processing:
	$line[0] = $event;   # add event type to line
	chomp $line[$#line]; #remove '\n' from last var

	return (\@line);
}

sub text2arr {
	my $fm = shift;
	my @array = ();

	open (my $fh, "<", $fm);

	while (<$fh>) {
		my $line = txt2arr_line $_;
		push @array, $line if (defined($line));

	}
	close $fh;
	return \@array;
}


my $arr  = text2arr $__fm;
my $i = 0;


my $hash = arr2hash $arr;

sub dump_hash {
	my $hash = shift;
	my $sort_func =  sub {${$hash}{$b}{$meta_str}[2] <=> ${$hash}{$a}{$meta_str}[2]};

	foreach my $sym (sort $sort_func  keys %{$hash}) {

		next if ($sym eq $meta_str);
		my $sym_hash = ${$hash}{$sym};
		my $t_line = ${$hash}{$sym}{$meta_str};
		printf "$sym : ${$t_line}[1], ${$t_line}[2], ${$t_line}[0]\n";

		foreach my $ev (keys %{$sym_hash}) {
			next if ($ev eq $meta_str);

			my $ev_hash = ${$sym_hash}{$ev};

			foreach my $acc (keys%{$ev_hash}) {
				my $line = ${$ev_hash}{$acc};
				printf "\t$sym : $ev: $acc: ${$line}[1], ${$line}[2], ${$line}[0]\n";
			}
		}
	}
}

dump_hash $hash;
