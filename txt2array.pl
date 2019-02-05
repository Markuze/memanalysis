#!/usr/bin/perl -w

use strict;
use autodie;
use Number::Format  'format_number';

my $meta_str = '__meta_total';

my $__fm = "mem.txt";
my $__fc = "cpu.txt";
my $__event = ""; # TODO: state?

#TODO: Please turn into .pm file

######################################## LIB FUNCS ##############################################
# Add array of CPU entries into a hash.
#	Assumed array structure:
#	# Children (1):Self (2):sys (3):usr (4):Command (5):Shared Object (6):Symbol (7)

my $__overhead 	= 0;
my $__weight 	= 1;
my $__count 	= 2;
my $__cycles 	= 3;
my $__children 	= 4;
my $__self 	= 5;

my $__count_s	= 0;
my $__snoop_s	= 1;
my $__tlb_s	= 2;
my $__locked_s	= 3;

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
	${$hash}{$symbol}{$meta_str}[$__children] = 0;
	${$hash}{$symbol}{$meta_str}[$__self] += $self;

	## Need same structure, as not to break sort
	${$hash}{$meta_str}{$meta_str}[$__cycles] = $cycles;
	${$hash}{$meta_str}{$meta_str}[$__children] += 0;
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

# Add array of CPU entries into a hash. collecting stats on Snooping, unique addr, Locked and TLB
#	Assumed array structure:
#	# Overhead (1):sys (2):usr (3):Local Weight (4):Memory access (5):Symbol (6):Shared Object (7):Data Symbol (8):Data Object (9):Snoop (10):TLB access (11):Locked (12)
#$__count_s	= 0;
#$__snoop_s	= 1;
#$__tlb_s	= 2;
#$__locked_s	= 3;
sub mem_arrline2stats {
		my $line = shift;
		my $hash = shift;
		#key
		my $event 	= ${$line}[0];
		my $symbol 	= ${$line}[8];
		my $access 	= ${$line}[5];

		#value
		my $func 		= ${$line}[6];
		my $snoop 		= ${$line}[10];
		my $tlb 		= ${$line}[11];
		my $locked 		= ${$line}[12];

		#total measured
		## Need same structure, as not to break sort
		${$hash}{$meta_str}{$meta_str}{$meta_str}[$__count_s]{$meta_str} ++ unless (defined(${$hash}{$symbol})); #count unique addresses
		${$hash}{$meta_str}{$meta_str}{$meta_str}[$__snoop_s]{$snoop} ++;
		${$hash}{$meta_str}{$meta_str}{$meta_str}[$__tlb_s]{$tlb} ++;
		${$hash}{$meta_str}{$meta_str}{$meta_str}[$__locked_s]{$locked} ++;

		#printf "$event: $symbol: $access > $oh: $weight\n";
		${$hash}{$symbol}{$event}{$access}[$__count_s]{$meta_str} ++;
		${$hash}{$symbol}{$event}{$access}[$__count_s]{$func} ++;
		${$hash}{$symbol}{$event}{$access}[$__snoop_s]{$meta_str} ++;
		${$hash}{$symbol}{$event}{$access}[$__snoop_s]{$snoop} ++;
		${$hash}{$symbol}{$event}{$access}[$__tlb_s]{$meta_str} ++;
		${$hash}{$symbol}{$event}{$access}[$__tlb_s]{$tlb} ++;
		${$hash}{$symbol}{$event}{$access}[$__locked_s]{$meta_str} ++;
		${$hash}{$symbol}{$event}{$access}[$__locked_s]{$locked} ++;

		#total per symbol
		${$hash}{$symbol}{$meta_str}{$meta_str}[$__count_s]{$meta_str} ++;
		${$hash}{$symbol}{$meta_str}{$meta_str}[$__count_s]{$func} ++;
		${$hash}{$symbol}{$meta_str}{$meta_str}[$__snoop_s]{$snoop} ++;
		${$hash}{$symbol}{$meta_str}{$meta_str}[$__tlb_s]{$tlb} ++;
		${$hash}{$symbol}{$meta_str}{$meta_str}[$__locked_s]{$locked} ++;

}
sub  stat_total_count {
	my $hash = shift;
	my $a	= shift;
	return ${$hash}{$b}{$meta_str}{$meta_str}[$__count_s]{$meta_str};
}
#
# Public
sub dump_stats {
	my $hash = shift;
	my $arr = ${$hash}{$meta_str}{$meta_str}{$meta_str};
	my $idx = $__self;


	foreach my $h (@{$arr}) {
		printf "----------------\n";
		foreach my $stat (sort {${$h}{$a} <=> ${$h}{$b}} keys %{$h}) {
			printf " $stat: ${$h}{$stat}\n";
		}
	}
}


#TODO: unify all loop functions
#A loop over an array of cpu entries (each element is an array of strings from a line in mem.dat file)
#return: updated hash.
sub mem_arr2stats {
	my $arr = shift;
	my $hash = shift;
	my %hash = (); #TODO: Add option to receive hash from the outside.

	$hash = \%hash unless (defined $hash);

	foreach (@{$arr}) {
		mem_arrline2stats $_, $hash;
	}
	return $hash;
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

## Public
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
		printf " %s\n", format_number($__event);
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

## Public
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

## Public
sub dump_hash {
	my $hash = shift;
	my $idx = $__self;
	my $sort_func =  sub {
				${$hash}{$b}{$meta_str}[$idx] <=> ${$hash}{$a}{$meta_str}[$idx]  # sort by self cycles
				};

	foreach my $sym (sort $sort_func  keys %{$hash}) {

		#next if ($sym eq $meta_str);
		my $sym_hash = ${$hash}{$sym};
		my $t_line = ${$hash}{$sym}{$meta_str};
		my $cycles = ${$t_line}[$__cycles]/100;

		next if (${$t_line}[$__children] == 0);

		if  (defined(${$t_line}[$__weight])) {
			printf "$sym : w:${$t_line}[$__weight], count: ${$t_line}[$__count],";
			printf " oh:%.2f , self: ${$t_line}[$__self](%sK) ch: , ${$t_line}[$__children] (%sK)\n",
					${$t_line}[$__overhead],
					format_number(${$t_line}[$__self] * $cycles/1000),
					format_number(${$t_line}[$__children] * $cycles/1000)
					;
		} else {
			printf "$sym : self: ${$t_line}[$__self] (%sK), ${$t_line}[$__children] (%sK)\n",
					format_number(${$t_line}[$__self] * $cycles/1000),
					format_number(${$t_line}[$__children] * $cycles/1000);
		}

		foreach my $ev (keys %{$sym_hash}) {
			next if ($ev eq $meta_str);

			my $ev_hash = ${$sym_hash}{$ev};

			foreach my $acc ( sort {${$ev_hash}{$b}[$__count] <=> ${$ev_hash}{$a}[$__count]} keys%{$ev_hash}) {
				my $line = ${$ev_hash}{$acc};
				printf "\t$sym : $ev: $acc: ${$line}[$__count], ${$line}[$__weight], ${$line}[$__overhead]\n";
			}
		}
	}
}

#################################################### Lib END

#Lib usage
my $arr  = text2arr $__fm;
my $stats = mem_arr2stats $arr;

dump_stats $stats;

my $hash = mem_arr2hash $arr;
$arr  = text2arr $__fc;
$hash = cpu_arr2hash $arr, $hash;

dump_hash $hash;
