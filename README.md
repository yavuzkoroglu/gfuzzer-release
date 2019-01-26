# gfuzzer-release
Grammar Fuzzer (gfuzzer): Fully Automated Test Generation, Execution, and Evaluation Tool

*gfuzzer* is a fully automated test generation, execution, and evaluation tool developed for compiler testing of reasoning engines.

*gfuzzer* is developed at and copyrighted on [Institute of Software Technology][7] at [Graz University of Technology][8] under GNU General Public License v3.0. See `COPYRIGHT.md` and `LICENSE` for details.

More information on the details of *gfuzzer* can be found in our paper, [Fully Automated Compiler Testing of a Reasoning Engine via Mutated Grammar Fuzzing][1].

### System Requirements

* [Perl][4] v5.14 or higher

Above is the only requirement of *gfuzzer*.

### Important Features

1. Accepts context-free grammars in BNF format. See `examples/bc.bnf`.
2. Accepts regular expressions as terminals. This feature works only if the grammar is used as a recognizer.
3. Comes with a stand alone recognizer and a stand alone tokenizer.
4. Can use separate grammars for generating and recognizing.
5. If mutation is going to be used, the grammar should be in at least [Chomsky Normal Form][2]. [Chomsky Reduced Form][3] is recommended.

### How to Use

```
Usage: perl gFuzzer.pl <GGF> <RGF> <RUT> "<PUT>" "<FM>" [mutate]
```

**GGF :** Generator-Grammar-File. 

**RGF :** Recognizer-Grammar-File. 

**RUT :** Rule-Under-Test. Most of the time, the root rule makes sense here.

**PUT :** Parser-Under-Test. Command to execute your tests. Tests are assumed to be entered from standard input.

**FM :** Fail Message. The message that Parser-Under-Test shows whenever the test input is not accepted. 

**mutate :** A keyword which triggers grammar mutation. It is optional.

### Example: Testing [bc][5]

[bc][5] is a known precision-calculator utility. Execute the following command from the main directory to generate, execute, and evaluate tests for 10 seconds.

```
timeout 10 perl gFuzzer.pl examples/bc.bnf examples/bc.bnf start "bc -sql" "(standard_in)" 2&>0
```

For using `timeout` command in Mac OS X, please check [Timeout Command on Mac OS X?][6].

If the command is executed successfully, two files will be generated in the main directory.

1. *passed.tests*
2. *failed.tests*

*failed.tests* should be empty because all test inputs should be valid and we assume that [bc][5] works correctly.

You can view *passed.tests* file to see the generated test inputs. Each test input is separated by a line.

This allows to count the number of passed tests as follows.

```
cat passed.tests | grep -e "--" | wc -l
```

Depending on your system, *gFuzzer* may generate more than a hundred tests per second.

### Replicating Our Research

[1]: https://www.google.com
[2]: https://en.wikipedia.org/wiki/Chomsky_normal_form
[3]: https://en.wikipedia.org/wiki/Chomsky_normal_form#Chomsky_reduced_form
[4]: https://www.perl.org/get.html
[5]: https://www.gnu.org/software/bc/manual/html_mono/bc.html
[6]: https://stackoverflow.com/questions/3504945/timeout-command-on-mac-os-x
[7]: http://www.ist.tugraz.at
[8]: https://www.tugraz.at