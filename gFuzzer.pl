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
use lib '.';
use warnings; no warnings 'once'; no warnings 'recursion';
use strict;
use autodie;
use v5.14;

use String::Random;

use grammar;

our $stringGenerator = String::Random->new;

our %coveredTerms;
our %testCases;
our $nFailed = 0;
our $nPassed = 0;

our $maxSymbols = 10;

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
    say 'under certain conditions; type "show c" for details.';
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
#	NONE
#
# Returns
#	UNUSED
#
sub showUsage {
	say '';
	say "$0 version 1901.26";
	say '';
	say "\tUsage: $0 <Generator-Grammar-File> <Recognizer-Grammar-File> <RuleUnderTest> \"<ParserUnderTest>\" \"<FailMessage>\" [mutate]";
	say '';
	say 'IMPORTANT: <Generator-Grammar-File> and <Recognizer-Grammar-File> must be in Chomsky Reduced Form';
	say 'Keyword mutate is optional. Triggers mgFuzzer';
	say '';
}

#
# Parameters
#	(1) Reference to Grammar
#	(2) Rule to generate sentence for
#	(3) MaxSymbols
#
# Returns
#	UNUSED
#
sub fuzzRule {
	my $grammarRef = shift @_ or die 'Illegal Argument Exception!';
	my $rule = shift @_ or die 'Illegal Argument Exception!';
	my $maxSymbols = shift @_ or die 'Illegal Argument Exception!';
	
	die "$rule IS NOT DEFINED!!" unless (defined $grammarRef->{$rule});
	
	my @terms = split /\|/, $grammarRef->{$rule};
	my @uncoveredTerms = ();
	for my $term (@terms) {
		push @uncoveredTerms, $term unless (defined $coveredTerms{"<${rule}> ::= ${term}"});
	}
	
	my $term = (@uncoveredTerms == 0) ? $terms[rand @terms] : $uncoveredTerms[rand @uncoveredTerms];
	$coveredTerms{"<${rule}> ::= ${term}"} = (defined $coveredTerms{"<${rule}> ::= ${term}"}) ? $coveredTerms{"<${rule}> ::= ${term}"} + 1 : 1;
	
	# Instantiate all subterms
	my $instantiatedTerm = '';
	my @subterms = ($term =~ /(<\S+>)|('\S+')/ig);
	for (@subterms) {
		if (defined) {
			if (/<(\S+)>/) {
				$instantiatedTerm .= ' ' . fuzzRule($grammarRef, $1, $maxSymbols);
			} elsif (/'(\S+)'/) {
				$instantiatedTerm .= " $1";
			}
		}
	}
	$instantiatedTerm =~ s/  / /g;
	$term = $instantiatedTerm;
	
	# Instantiate all regular expressions
	while ($term =~ /(.*)\/(\S+)\/(.*)/) {
		my ($prefix, $expression, $suffix) = ($1, $2, $3);
		
		# Replace all stars with random [0, maxSymbols]
		while ($expression =~ /(.*)\*(.*)/) {
			$expression = $1 . '{' . int(rand($maxSymbols)) . '}' . $2;
		}
		
		# Replace all pluses with random [1, maxSymbols]
		while ($expression =~ /(.*)\+(.*)/) {
			$expression = $1 . '{' . (int(rand($maxSymbols-1)) + 1) . '}' . $2;
		}
		
		$term = $prefix.$stringGenerator->randregex($expression).$suffix;
	}
	
	# Insert all newline characters
	$term =~ s/\\n/\n/g;
	
	# Remove all ' signs
	$term =~ s/'//g;
	$term =~ s/ //g;
	
	return $term;
}

sub main {
	my $mgFuzzer = ("@ARGV" =~ /mutate/);
	my $generatorGrammarFile = shift @ARGV or (showUsage(), exit);
	my $recognizerGrammarFile = shift @ARGV or (showUsage(), exit);
	my $ruleUnderTest = shift @ARGV or (showUsage(), exit);
	my $parserUnderTest = shift @ARGV or (showUsage(), exit);
	my $failMessage = shift @ARGV or (showUsage(), exit);
	
	say "GENERATOR GRAMMAR FILE = $generatorGrammarFile";
	say "RECOGNIZER GRAMMAR FILE = $recognizerGrammarFile";
	say "RULE UNDER TEST = $ruleUnderTest";
	say "PARSER UNDER TEST = $parserUnderTest";
	say "FAIL MESSAGE = $failMessage";
	say 'MUTATION = ' . ($mgFuzzer ? 'enabled' : 'disabled');
	
	if ($ruleUnderTest =~ /<(\S+)>/) {
		$ruleUnderTest = $1;
	}
	
	say '';
	say "LOADING = $generatorGrammarFile";
	my %originalGrammar = grammar::load($generatorGrammarFile);
	say "LOADED = $generatorGrammarFile";
	say '';
	
	die "Rule <$ruleUnderTest> NOT FOUND in $generatorGrammarFile!" unless (defined $originalGrammar{$ruleUnderTest});
	
	open PASSEDTESTS, ">passed.tests";
	open FAILEDTESTS, ">failed.tests";
	
	for(my $tid = 1;;$tid++) {
		my %mutatedGrammar = grammar::mutate($ruleUnderTest) if ($mgFuzzer);
		
		my $testInput = fuzzRule(($mgFuzzer ? \%mutatedGrammar : \%originalGrammar), $ruleUnderTest, $maxSymbols);
		
		my $parserOutput = `echo '$testInput' | $parserUnderTest 2>&1`;
		
		my $recognizerOutput = 'Recognizable';
		if ($mgFuzzer) {
			open CORPUS, ">temporary.file";
			my $test = $testInput;
			$test =~ s/\R//g;
			$test =~ s/\n//g;
			print CORPUS $test;
			close CORPUS;
			$recognizerOutput = `./tokenizer.pl $recognizerGrammarFile temporary.file | ./recognizer.pl $recognizerGrammarFile $ruleUnderTest`;
			unlink 'temporary.file';
		}
		
		if ($parserOutput =~ /$failMessage/) {
			if ($recognizerOutput =~ /Unrecognizable/) {
				$nPassed++;
				say PASSEDTESTS $testInput;
				say PASSEDTESTS "-------------------------------------";
			} else {
				$nFailed++;
				say FAILEDTESTS $testInput;
				say FAILEDTESTS "-------------------------------------";
			}
		} elsif ($recognizerOutput =~ /Unrecognizable/) {
				$nFailed++;
				say FAILEDTESTS $testInput;
				say FAILEDTESTS "-------------------------------------";
		} else {
			$nPassed++;
			say PASSEDTESTS $testInput;
			say PASSEDTESTS "--------------------------------------";
		}
		
		open RESULTS, ">results.txt";
		say RESULTS "# PASSED = $nPassed";
		say RESULTS "# FAILED = $nFailed";
		say RESULTS "% TERM COVERAGE = " . (100 * (scalar keys %coveredTerms) / grammar::getTermCount()) unless ($mgFuzzer);
		close RESULTS;
	}
	
	close PASSEDTESTS;
	close FAILEDTESTS;
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
