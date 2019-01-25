#
#   gfuzzer: Fully Automated Test Generation, Execution, and Evaluation Tool
#   Copyright (C) 2019 Institute for Software Technology in Graz University of Technology
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
package grammar;

use warnings; no warnings qw(once recursion);
use strict;
use autodie;
use v5.14;

{
	my %myGrammar = ();
	my %terminalRules = ();
	my %regexRules = ();
	my $nTerms = 0;
	
	#
	# Parameters
	#	(1) File Name
	#
	# Returns
	#	HASH: Grammar
	#
	sub load {
		my $inputFileName = shift @_ or die 'Illegal Argument Exception!';
		open INPUT, "<$inputFileName" or die "$inputFileName NOT FOUND!";
		%myGrammar = ();
		while (my $line = <INPUT>) {
			chomp $line;
			if ($line =~ /^\s*<(\S+)>\s*::=(.*)$/) {
				my ($ruleName, $terms) = ($1, $2);
				
				for my $term (split /\|/, $terms) {
					$nTerms++;
					if ($term =~ /'(\S+)'/) {
						$_ = $1; s/\\n//g;
						if (defined $terminalRules{$_}) {
							$terminalRules{$_} = "$terminalRules{$_}|$ruleName";
						} else {
							$terminalRules{$_} = $ruleName;
						}
					} elsif ($term =~ /\/(.*)\//) {
						$_ = $1;
						$regexRules{$_} = defined $regexRules{$_} ? $regexRules{$_}."|$ruleName" : $ruleName;
					}
				}
				
				if (defined $myGrammar{$ruleName}) {
					$myGrammar{$ruleName} .= " | $terms";
				} else {
					$myGrammar{$ruleName} = $terms;
				}
			}
		}
		close INPUT;
		
		return %myGrammar;
	}
	
	#
	# Parameters
	#	NONE
	#
	# Returns
	#	ARRAY: List of candidate rules
	#
	sub findCandidateRulesFor {
		my $str = "@_";
		my @candidates = ();
		for (sort keys %myGrammar) {
			push @candidates, $_ if ($myGrammar{$_} =~ /$str/);
		}
		return @candidates;
	}
	
	#
	# Parameters
	#	NONE
	#
	# Returns
	#	HASH: Grammar
	#
	sub getGrammar {
		return %myGrammar;
	}
	
	#
	# Parameters
	#	NONE
	#
	# Returns
	#	SCALAR: # Terms in the grammar
	#
	sub getTermCount {
		return $nTerms;
	}
	
	#
	# Parameters
	#	(1) Candidate Terminal String
	#
	# Returns
	#	ARRAY: List of applicable rules or ();
	#
	sub getPossibleRulesOf {
		my $terminal = shift @_;
		
		my @possibleRules = ();
		if ($terminal) {
			push @possibleRules, (split /\|/, $terminalRules{$terminal}) if (defined $terminalRules{$terminal});
			for my $regex (keys %regexRules) {
				push @possibleRules, split(/\|/, $regexRules{$regex}) if ($terminal =~ /$regex/);
			}
		}
		
		return @possibleRules;
	}
	
	#
	# Parameters
	#	NONE
	#
	# Returns
	#	HASH: Mutated Grammar
	#
	sub mutopTerminalReplacement {
		my %mutatedGrammar = %myGrammar;
		
		my @terminalRules = ();
		for my $rule (keys %mutatedGrammar) {
			push @terminalRules, $rule if ($rule =~ /'/);
		}
		
		# Return () if there are not enough terminals
		return () unless (@terminalRules >= 2);
		
		my $targetRule = $terminalRules[rand @terminalRules];
		my $replacement; 
		do {
			$replacement = $terminalRules[rand @terminalRules];
		} until ($targetRule ne $replacement);
		
		$mutatedGrammar{$replacement} =~ /('.*')/;
		my $replaceStr = $1;
		$mutatedGrammar{$targetRule} =~ s/'.*'/$replaceStr/;
		
		# Return Mutated Grammar
		return %mutatedGrammar;
	}

	#
	# Parameters
	#	NONE
	#
	# Returns
	#	HASH: Mutated Grammar
	#
	sub mutopDeletion {
		my $root = shift @_ or die 'Illegal Argument Exception!';
		my %mutatedGrammar = %myGrammar;
		
		my @rules = ();
		for (keys %mutatedGrammar) {
			push @rules, $_ unless ($_ eq $root);
		}
		
		# Return () if there are not enough rules
		return () unless (@rules > 1);
		
		my $targetRule = $rules[rand @rules];
		
		$mutatedGrammar{$targetRule} = "''";
		
		# Return Mutated Grammar
		return %mutatedGrammar;
	}

	#
	# Parameters
	#	NONE
	#
	# Returns
	#	HASH: Mutated Grammar
	#
	sub mutopDuplication {
		my %mutatedGrammar = %myGrammar;
		my @rules = keys %mutatedGrammar;
		
		my $targetRule = $rules[rand @rules];
		my $newRule = "${targetRule}_duplicated";
		my $oldTerms = $mutatedGrammar{$targetRule};
		
		$mutatedGrammar{$targetRule} = "<$newRule> <$newRule>";
		$mutatedGrammar{$newRule} = $oldTerms;
		
		# Return Mutated Grammar
		return %mutatedGrammar;
	}
	
	#
	# Parameters
	#	NONE
	#
	# Returns
	#	HASH: Mutated Grammar
	#
	sub mutopExchange {
		my %mutatedGrammar = %myGrammar;
		my @nonTerminalRules = ();
		for my $rule (keys %mutatedGrammar) {
			push @nonTerminalRules, $rule if ($mutatedGrammar{$rule} =~ /<\S+>/);
		}
		
		# Return () if there are not enough rules
		return () unless (@nonTerminalRules > 0);
		
		my $targetRule = $nonTerminalRules[rand @nonTerminalRules];
		
		my @candidates = ();
		for (split /\|/, $mutatedGrammar{$targetRule}) {
			push @candidates, $_ if (/<.*>\s*<.*>/);
		}
		
		die ('Something is very wrong!') if (@candidates == 0);
		my $candidate = $candidates[rand @candidates];
		
		$candidate =~ /<(\S+)>\s*<(\S+)>/;
		my $replacement = "<$2> <$1>";
		$mutatedGrammar{$targetRule} =~ s/$candidate/$replacement/;
		
		# Return Mutated Grammar
		return %mutatedGrammar;
	}
	
	#
	# Parameters
	#	NONE
	#
	# Returns
	#	HASH: Mutated Grammar
	#
	sub mutopRecursionInsertion {
		my %mutatedGrammar = %myGrammar;
		my @rules = keys %mutatedGrammar;
		
		my $targetRule = $rules[rand @rules];
		
		$mutatedGrammar{$targetRule} = "$mutatedGrammar{$targetRule} | <$targetRule>";
		
		# Return Mutated Grammar
		return %mutatedGrammar;
	}
	
	#
	# Parameters
	#	NONE
	#
	# Returns
	#	HASH: Mutated Grammar
	#
	sub mutopTerminalInsertion {
		my %mutatedGrammar = %myGrammar;
		my @chars = ('a','A','.','!','@','&','%','+','?','*','0','1','-','_',';');
		my $char = $chars[rand @chars];
		
		my @nonTerminalRules = ();
		for my $rule (keys %mutatedGrammar) {
			push @nonTerminalRules, $rule if ($mutatedGrammar{$rule} =~ /<\S+>/);
		}
		
		# Return () if there are not enough rules
		return () unless (@nonTerminalRules > 0);
		
		my $targetRule = $nonTerminalRules[rand @nonTerminalRules];
		
		my @candidates = ();
		for (split /\|/, $mutatedGrammar{$targetRule}) {
			push @candidates, $_ if (/<.*>\s*<.*>/);
		}
		
		die ('Something is very wrong!') if (@candidates == 0);
		my $candidate = $candidates[rand @candidates];
		
		$candidate =~ /<(\S+)>\s*<(\S+)>/;
		my ($first, $second) = ($1, $2);
		my $rnd = rand;
		my $replacement = '';
		if ($rnd < 0.33) {
			$replacement = "'$char' <$1> <$2>";
		} elsif ($rnd < 0.66) {
			$replacement = "<$1> '$char' <$2>";
		} else {
			$replacement = "<$1> <$2> '$char'";
		}
		$mutatedGrammar{$targetRule} =~ s/$candidate/$replacement/;
		
		# Return Mutated Grammar
		return %mutatedGrammar;
	}
	
	my %mutation_operators = (
		'TR' => \&mutopTerminalReplacement,
		'DE' => \&mutopDeletion,
		'DU' => \&mutopDuplication,
		'EX' => \&mutopExchange,
		'RI' => \&mutopRecursionInsertion,
		'TI' => \&mutopTerminalInsertion
	);
	#
	# Parameters
	#	NONE
	#
	# Returns
	#	HASH: Mutated Grammar
	sub mutate {
		# Get all mutation operators
		my @mutops = keys %mutation_operators;
		
		my %mutatedGrammar = ();
		until (scalar keys %mutatedGrammar > 0) {
			# Select one mutation operator randomly
			my $mutop = $mutops[rand @mutops];
			
			# Apply
			say "APPLYING = $mutop";
			%mutatedGrammar = $mutation_operators{$mutop}->(@_);
		}
		
		return %mutatedGrammar;
	}
}

return 1;
