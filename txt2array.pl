#!/usr/bin/perl -w

use strict;
use autodie;

my $meta_str = '__meta_total';

my $__fm = "mem.txt";
my $__fc = "cpu.txt";
my $__event = "";

######################################## LIB FUNCS ##############################################
# Add array of CPU entries into a hash.
#	Assumed array structure:
#	# Children (1):Self (2):sys (3):usr (4):Command (5):Shared Object (6):Symbol (7)

my $__overhead = 0;
my $__weight = 1;
my $__count = 2;
my $__cycles = 3;
my $__children = 4;
my $__self = 5;

sub cpu_arrline2hash {
	my $line = shift;
	my $hash = shift;

	#key
	my $symbol 	= ${$line}[7];

	#value
	my $cycles 	= ${$line}[0];
	my $children 	= ${$line}[1];
	my $self 	= ${$line}[2];

	chop $self;
	chop $children;

	${$hash}{$symbol}{$meta_str}[$__cycles] = $cycles;
	${$hash}{$symbol}{$meta_str}[$__children] += $children;
	${$hash}{$symbol}{$meta_str}[$__self] += $self;

	## Need same structure, as not to break sort
	${$hash}{$meta_str}{$meta_str}[$__cycles] = $cycles;
	${$hash}{$meta_str}{$meta_str}[$__children] += $children;
	${$hash}{$meta_str}{$meta_str}[$__self] += $self;
}

# Add array of CPU entries into a hash.
#	Assumed array structure:
#	# Overhead (1):sys (2):usr (3):Local Weight (4):Memory access (5):Symbol (6):Shared Object (7):Data Symbol (8):Data Object (9):Snoop (10):TLB access (11):Locked (12)
sub mem_arrline2hash {
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
		${$hash}{$symbol}{$event}{$access}[$__overhead] += $oh;
		${$hash}{$symbol}{$event}{$access}[$__weight] += $weight;
		${$hash}{$symbol}{$event}{$access}[$__count] ++; #count

		${$hash}{$symbol}{$meta_str}[$__overhead] += $oh;
		${$hash}{$symbol}{$meta_str}[$__weight] += $weight;
		${$hash}{$symbol}{$meta_str}[$__count] ++;

		## Need same structure, as not to break sort
		${$hash}{$meta_str}{$meta_str}[$__overhead] += $oh;
		${$hash}{$meta_str}{$meta_str}[$__weight] += $weight;
		${$hash}{$meta_str}{$meta_str}[$__count] ++;

		unless (defined (${$hash}{$symbol}{$meta_str}[$__cycles])) {
			${$hash}{$symbol}{$meta_str}[$__cycles] = 0;
			${$hash}{$symbol}{$meta_str}[$__children] = 0;
			${$hash}{$symbol}{$meta_str}[$__self] = 0;

			${$hash}{$meta_str}{$meta_str}[$__cycles] = 0;
			${$hash}{$meta_str}{$meta_str}[$__children] = 0;
			${$hash}{$meta_str}{$meta_str}[$__self] = 0;
		}

}

#A loop over an array of cpu entries (each element is an array of strings from a line in cpu.dat file)
sub cpu_arr2hash {
	my $arr = shift;
	my $hash = shift;
	my %hash = (); #TODO: Add option to receive hash from the outside.

	$hash = \%hash unless (defined $hash);

	foreach (@{$arr}) {
		cpu_arrline2hash $_, $hash;
	}
	return $hash;
}

#A loop over an array of cpu entries (each element is an array of strings from a line in mem.dat file)
#return: updated hash.
sub mem_arr2hash {
	my $arr = shift;
	my $hash = shift;
	my %hash = (); #TODO: Add option to receive hash from the outside.

	$hash = \%hash unless (defined $hash);

	foreach (@{$arr}) {
		mem_arrline2hash $_, $hash;
	}
	return $hash;
}

# break a line from cpu/mem.txt file (cpu/mem.dat), into an array.
# each line is parsed into an array of strings.
# return: array of strings
sub txt2arr_line {
	my $line = shift;

	#Get CPU event (Mem.dat Only): line example:
	# Samples: 677K of event 'cpu/mem-loads/p'
	if ($line =~ /# Samples/) {
		$line =~ /Samples:\s+([\d+\w]+).*\s(\S+)\s*$/;
		#printf "$1 > $2";
		$__event = $2;
		printf "$__event\n";
		return undef;
	}
	# Get cycles: (CPU Only)
	if ($line =~ /# Event count/) {
		$line =~ /\s(\d+)$/;
		$__event = $1 if defined ($1);
		printf "$__event\n";
		return undef;
	}
	# Get Key: (CPU/Mem)
	if ($line =~ /# Overhead|# Children/) {
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
	$line[0] = $__event;   # add event type to line
	chomp $line[$#line]; #remove '\n' from last var

	return (\@line);
}

#loop over a cpu/mem.txt file, each line is paresed into an array by txt2arr_line
#return: an array of arrays.
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

sub dump_hash {
	my $hash = shift;
	my $idx = $__self;
	my $sort_func =  sub {
				${$hash}{$b}{$meta_str}[$idx] <=> ${$hash}{$a}{$meta_str}[$idx]  # sort by self cycles
				};

	foreach my $sym (sort $sort_func  keys %{$hash}) {

		next if ($sym eq $meta_str);
		my $sym_hash = ${$hash}{$sym};
		my $t_line = ${$hash}{$sym}{$meta_str};
		my $cycles = ${$t_line}[$__cycles]/100;

		next if (${$t_line}[$__children] == 0);

		if  (defined(${$t_line}[$__weight])) {
			printf "$sym : w:${$t_line}[$__weight], count: ${$t_line}[$__count],";
			printf " oh:%.2f , self: ${$t_line}[$__self](%dK) ch: , ${$t_line}[$__children] (%dK)\n",
					${$t_line}[$__overhead],
					${$t_line}[$__self] * $cycles/1000,
					${$t_line}[$__children] * $cycles/1000
					;
		} else {
			printf "$sym : self: ${$t_line}[$__self] (%dK), ${$t_line}[$__children] (%dK)\n",
					${$t_line}[$__self] * $cycles/1000, ${$t_line}[$__children] * $cycles/1000;
		}

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

#################################################### Lib END

my $arr  = text2arr $__fm;
my $i = 0;


my $hash = mem_arr2hash $arr;
$arr  = text2arr $__fc;
$hash = cpu_arr2hash $arr, $hash;

dump_hash $hash;
