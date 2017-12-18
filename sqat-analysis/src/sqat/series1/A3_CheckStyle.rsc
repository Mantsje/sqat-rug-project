module sqat::series1::A3_CheckStyle

import IO;
import sqat::series1::longLines;
import sqat::series1::customStyle;
import sqat::series1::avoidStarImport;

/*

Assignment: detect style violations in Java source code.
Select 3 checks out of this list:  http://checkstyle.sourceforge.net/checks.html
Compute a set[Message] (see module Message) containing 
check-style-warnings + location of  the offending source fragment. 

Plus: invent your own style violation or code smell and write a checker.

Note: since concrete matching in Rascal is "modulo Layout", you cannot
do checks of layout or comments (or, at least, this will be very hard).

JPacman has a list of enabled checks in checkstyle.xml.
If you're checking for those, introduce them first to see your implementation
finds them.

Questions
- for each violation: look at the code and describe what is going on? 
  Is it a "valid" violation, or a false positive?

Tips 

- use the grammar in lang::java::\syntax::Java15 to parse source files
  (using parse(#start[CompilationUnit], aLoc), in ParseTree)
  now you can use concrete syntax matching (as in Series 0)

- alternatively: some checks can be based on the M3 ASTs.

- use the functionality defined in util::ResourceMarkers to decorate Java 
  source editors with line decorations to indicate the smell/style violation
  (e.g., addMessageMarkers(set[Message]))

  
Bonus:
- write simple "refactorings" to fix one or more classes of violations 

*/

//loc testFile = |project://sqat-analysis/src/sqat/series1/testFiles/A1_test.java|;

void checkStyle(loc project=|project://jpacman-framework/src|) {
	llines = checkStyleLongLines(proj=project, threshold=80, printLines=false);
	blines = checkStyleBraces(proj=project, printLocs=false);
	silines = checkStyleStarImports(proj=project, printLocs=false);
	allMethods = checkStyleNumberOfMethods(proj=project, threshold=8, printLines=false);
	
	
	
	println("The long lines:");
	for (line <- llines) {
		println(line);
	}
	println("\nThe curly brace lines:");
	for (line <- blines) {
		println(line);
	}
	println("\nThe star import lines:");
	for (line <- blines) {
		println(line);
	}
	return;
}
