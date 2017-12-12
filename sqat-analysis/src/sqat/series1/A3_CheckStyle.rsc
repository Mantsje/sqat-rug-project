module sqat::series1::A3_CheckStyle

import Java17ish;
import Message;
import IO;
import lang::java::\syntax::Java15;
import ParseTree;
import util::ResourceMarkers;
import util::FileSystem;

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

//set[Message] checkStyle(loc project) {
//  set[Message] result = {};
//  
//  // to be done
//  // implement each check in a separate function called here. 
//  
//  return result;
//}

int findLineLength(str functionBody) {
	println(functionBody);
	return -1;
}

//Should return a map for every line and its linesize
map[loc, int] methodLines(start[CompilationUnit] cu) {
  result = ();
  visit (cu) {
    case theMethod:(MethodDec)`<MethodDecHead m> <MethodBody body>`: 
       result[theMethod@\loc] = findLineLength("<body>");
  } 
  return result;
}

// analyze
map[loc, int] bigLines(int threshold, map[loc, int] lineSize) 
  = ( l: lineSize[l] | loc l <- lineSize, lineSize[l] >= threshold );


// synthesize
set[Message] warningsForLongLines(map[loc, int] ms) 
  = { warning("Long line!", l) | l <- ms  };
  

// top-level
set[Message] checkStyle(loc project) {
  ms = ();
  for (loc l <- files(project), l.extension == "java") {
    ms += methodLines(parse(#start[CompilationUnit], l, allowAmbiguity=true));
  }
  return warningsForLongLines(bigLines(100, ms));
}

void main(loc project) {
  //addMessageMarkers(checkStyle(project));
  checkStyle(project);
}
