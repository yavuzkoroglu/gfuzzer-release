#!/usr/bin/env perl
#
#   gfuzzer: Fully Automated Test Generation, Execution, and Evaluation Tool
#   Copyright (C) 2019 Institute for Software Technology at Graz University of Technology
#
#   This file is part of gfuzzer.
#
#   gfuzzer is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   gfuzzer is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with gfuzzer.  If not, see <https://www.gnu.org/licenses/>.
#
#   mail: ykoerogl@ist.tugraz.at 
#   address: Inffeldgasse 16b/II, 8010 Graz/AUSTRIA
#
use warnings; no warnings qw(once recursion);
use strict;
use autodie;
use v5.14;

use grammar;

#
# Parameters
#   NONE
#
# Returns
#   UNUSED
#
sub showCopyright {
    say 'gfuzzer Copyright (C) 2019 Institute for Software Technology at Graz University of Technology';
    say 'This program comes with ABSOLUTELY NO WARRANTY; for details type "show w".';
    say 'This is free software, and you are welcome to redistribute it';
}

#
# Parameters
#   NONE
#
# Returns
#   UNUSED
#
sub showLicense {
    open LICENSE, "<LICENSE" or die("No LICENSE file found!");
    print while(<LICENSE>);
    close LICENSE;
}

#
# Parameters
#   NONE
#
# Returns
#   UNUSED
#
sub showWarranty {
    say 'This program is distributed in the hope that it will be useful,';
    say 'but WITHOUT ANY WARRANTY; without even the implied warranty of';
    say 'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the';
    say 'GNU General Public License for more details.';
    say '';
    say 'You should have received a copy of the GNU General Public License';
    say 'along with this program.  If not, see <https://www.gnu.org/licenses/>.';
}

#
# Parameters
#	NONE
#
# Returns
#	UNUSED
#
sub showUsage {
	say '';
	say "$0 version 1901.24, Yavuz Koroglu";
	say '';
	say "\tUsage: $0 <BNF-File> <RootRule> [<Token-File>]";
	say '';
	say 'IMPORTANT: <BNF-File> must be in Chomsky Normal Form';
	say '';
	say '<Token-File> is optional. If not given, standard input is used.';
	say '';
	say 'NOTE: This is a CKY-Parser.';
	say '';
}

#
# Parameters
#	NONE
#
# Returns
#	UNUSED
#
sub main {
	my $inputFileName = shift @ARGV or (showUsage(), exit);
	my $root = shift @ARGV or (showUsage(), exit);
	
	if (@ARGV > 0) {
		open INPUT, "<$ARGV[0]";
		@_ = <INPUT>;
		close INPUT;
	} else {
		@_ = <STDIN>;
	}
	
	# Exit if there are no candidate tokenizations
	say "Unrecognizable" and exit unless (@_);
	
	my %myGrammar = grammar::load($inputFileName);
	
	for (@_) {
		my @tokens = split / /;
		my $n = $#tokens;
		
		my %matrix = ();
		for my $i (0..$n) {
			my $token = $tokens[$i];
			if ($token =~ /\{(.*)\}/) {
				$matrix{"$i:$i"} = $1;
			} else {
				say "Unrecognizable" and exit;
			}
		}
		
		for my $i (1..$n) {
			for my $j (reverse (0..($i-1))) {
				
				my %allCandidates = ();
				my $i2 = $i - 1;
				my $j2 = $i;
				while ($i2 >= $j) {
					if (defined $matrix{"$i2:$j"} and defined $matrix{"$i:$j2"}) {
						for my $first (split /,/, $matrix{"$i2:$j"}) {
							for my $second (split /,/, $matrix{"$i:$j2"}) {
								#say "CONSIDERING = $first - $second"; 
								for (grammar::findCandidateRulesFor("<$first> <$second>")) {
									$allCandidates{$_} = "";
								}
							}
						}
					}
					
					$i2--;
					$j2--;
				}
				
				$matrix{"$i:$j"} = join ',', (sort keys %allCandidates);
			}
		}
		
		open CSV, ">recognizer_proof.csv";
		for my $i (0..$n) {
			for my $j (0..$i) {
				my $im1 = $i - 1;
				my $str = $matrix{"$i:$j"};
				$str =~ s/,/ OR /g;
				print CSV "$i:$j -> " . $str . ",";
			}
			say CSV '';
		}
		
		say "Recognizable" and exit if (defined $matrix{"$n:0"} and $matrix{"$n:0"} =~ /$root/);
	}
	
	say "Unrecognizable" and exit;
}

showCopyright();
if ("@_" =~ /show w/) {
    showWarranty();
    exit;
} elsif ("@_" =~ /show c/) {
    showLicense();
    exit;
} else {
    main();    
}
