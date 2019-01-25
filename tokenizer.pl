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
    say 'This program comes with ABSOLUTELY NO WARRANTY; for details type "show w".'
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
	say "\tUsage: $0 <BNF-File> [<Input-File>]";
	say '';
	say 'IMPORTANT: <BNF-File> must be in Chomsky Normal Form';
	say '';
	say '<Input-File> is optional. If not given, standard input is used.';
	say '';
}

#
# Parameters
#	(1) Previous Terms
#	(...) Remaining Letters
#
# Returns
#	UNUSED
#
sub tokenize {
	my $prevTerms = shift @_;
	
	my $line = "@_"; chomp $line;
	say $prevTerms and return if ($line =~ /^\s*$/);
	
	my $curToken = '';
	my $currentTerm = '';
	while (@_ > 0) {
		$_ = shift @_;
		next unless (defined);
		next if (/ /);
		$curToken .= $_;
		next if (@_ > 0 and $curToken =~ /[a-zA-Z0-9_]/ and $_[0] =~ /[a-zA-Z0-9_]/);
		my @candidateRules = grammar::getPossibleRulesOf($curToken);
		if (@candidateRules > 0) {
			$currentTerm = '{' . (join ',', @candidateRules) . '}';
			
			if ($prevTerms eq '') {
				tokenize($currentTerm, @_);
			} else {
				tokenize("$prevTerms $currentTerm", @_);
			}
		}
	}
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
	grammar::load($inputFileName);
	
	if (@ARGV > 0) {
		open INPUT, "<$ARGV[0]";
		@_ = <INPUT>;
		close INPUT;
	} else {
		@_ = <STDIN>;
	}
	
	$_ = "@_"; s/\\n//g;
	tokenize('', split //);
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
