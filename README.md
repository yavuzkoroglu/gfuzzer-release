# gfuzzer-release
Grammar Fuzzer (gfuzzer): Fully Automated Test Generation, Execution, and Evaluation Tool

*gfuzzer* is a fully automated test generation, execution, and evaluation tool developed for compiler testing of reasoning engines.

*gfuzzer* is developed at and copyrighted on [Institute of Software Technology][7] at [Graz University of Technology][8] under GNU General Public License v3.0. See the copyright notice at the end of this document for details.

More information on the details of *gfuzzer* can be found in our paper, [Fully Automated Compiler Testing of a Reasoning Engine via Mutated Grammar Fuzzing][10]. All test inputs generated for this paper can be found [here][9].

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
timeout 10 perl gFuzzer.pl examples/bc.bnf examples/bc.bnf start "bc -sql " "(standard_in)"
```

For using `timeout` command in Mac OS X, please check [Timeout Command on Mac OS X?][6].

If the command is executed successfully, two files will be generated in the main directory.

1. *passed.tests*
2. *failed.tests*

You can view these files to see the generated test inputs. Each test input is separated by a line.

This allows to count the number of passed tests as follows.

```
cat passed.tests | grep -e "--" | wc -l
```

You can also count the number of failed tests as follows.

```
cat failed.tests | grep -e "--" | wc -l
```

Depending on your system, *gFuzzer* may generate more than a hundred tests per second.

### Reproducing Our Experiments

During experiments, we used the following parameters for *gfuzzer*.

**GGF :** `AST19/generator.bnf`

**RGF :** `AST19/recognizer.bnf`

**RUT :** `start`

**PUT :** `"java -jar AST19/ATMS.jar "`

**FM :** `"Compile Failed"`

**mutate :** We used this keyword to switch between *gfuzzer* and *mgfuzzer*.

Note that we used Java version "1.8.0_112" during experiments. 

Please feel free to contact us if you are unable to reproduce the experiments.

### Copyright Notice

gfuzzer: Fully Automated Test Generation, Execution, and Evaluation Tool
Copyright (C) 2019 Institute for Software Technology at Graz University of Technology

gfuzzer is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

gfuzzer is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with gfuzzer. If not, see <https://www.gnu.org/licenses/>.

* **mail:** ykoerogl@ist.tugraz.at
* **address:** Inffeldgasse 16b/II, 8010 Graz/AUSTRIA

[1]: https://www.google.com
[2]: https://en.wikipedia.org/wiki/Chomsky_normal_form
[3]: https://en.wikipedia.org/wiki/Chomsky_normal_form#Chomsky_reduced_form
[4]: https://www.perl.org/get.html
[5]: https://www.gnu.org/software/bc/manual/html_mono/bc.html
[6]: https://stackoverflow.com/questions/3504945/timeout-command-on-mac-os-x
[7]: http://www.ist.tugraz.at
[8]: https://www.tugraz.at
[9]: https://www.cmpe.boun.edu.tr/~yavuz.koroglu/AST19/
[10]: https://www.cmpe.boun.edu.tr/~yavuz.koroglu/publications/AST19.pdf
