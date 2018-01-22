module sqat::series1::A1_SLOC_version2

import IO;
import ParseTree;
import String;
import util::FileSystem;

/* 
Count Source Lines of Code (SLOC) per file:
- ignore comments
- ignore empty lines

Tips
- use locations with the project scheme: e.g. |project:///jpacman/...|
- functions to crawl directories can be found in util::FileSystem
- use the functions in IO to read source files

Answer the following questions:
- what is the biggest file in JPacman?
A: <|src/main/java/nl/tudelft/jpacman/level/Level.java|, 179>
- what is the total size of JPacman?
A: total size = 2459
- is JPacman large according to SIG maintainability?
A: No <<< 0-66 KLOC
- what is the ratio between actual code and test code size?
A: main = 1901, tests = 557

Sanity checks:
- write tests to ensure you are correctly skipping multi-line comments
- and to ensure that consecutive newlines are counted as one.
- compare you results to external tools sloc and/or cloc.pl

Bonus:
- write a hierarchical tree map visualization using vis::Figure and 
  vis::Render quickly see where the large files are. 
  (https://en.wikipedia.org/wiki/Treemapping) 

*/

alias SLOC = map[loc file, tuple[int sloc, int comments, int blanks] info];

SLOC sloc(loc project) {
	SLOC result = ();
  	FileSystem fs = crawl(project);
	result = filterFiles(fs);
	return result;
}         

void main(loc proj=|project://jpacman-framework/src|) {
	SLOC res = sloc(proj);
	for(f <- res) {
		print(f);
		print(" : ");
		println(res[f]);
	}
	println("total SLOC: 		  <(0 | it + res[x].sloc	| x <- res)>");
	println("total comment lines: <(0 | it + res[x].comments| x <- res)>");
	println("total blank lines:   <(0 | it + res[x].blanks	| x <- res)>");
}

tuple[int, int, int] SLOCinLines(list[str] lines) {
	linesOfCode = 0; nComments = 0; blanks = 0;
	lines1 = [ trim(x) | str x <- lines, trim(x) != ""];
	lines2 = [x | str x <- lines1, x[0..2] != "//"];
	inComment = false;
	for (line <- lines2) {
		addLine = false;
		//Is there an opening comment?
		if(!inComment && /\/\*/ := line) {
			inComment = true;
			//Is there code before the opening of comment
			if (/\S+.*\/\*/ := line) {
				addLine = true;
			}
			// Is there also a closing comment
			if (/\*\// := line) {
				//Is there following code?
				if (/\*\/.*\S+/ := line) {
					addLine = true;	
				}
				inComment = false;
			} 
			if (addLine) {
				linesOfCode += 1;
			} else {
				nComments += 1;
			}
		//Is there a closing comment?
		} else if (inComment && /\*\// := line) {
			inComment = false;
			//Is there code after the closing comment?
			if (/\*\/\S+/ := line) {
				linesOfCode += 1;
			} else {
				nComments += 1;
			}								
		} else if (!inComment) {
			linesOfCode += 1;
		} else {
			nComments += 1;
		}
	}
	nComments += size(lines1) - size(lines2);
	blanks += size(lines) - size(lines1);

	result = <linesOfCode, nComments, blanks>;
	return result;
}

SLOC filterFiles(FileSystem fs) {
	SLOC result = ();
	visit (fs) {
		case file(loc l): {
			if( (/\.java/ := l.path)) {
				allLines = readFileLines(l);
				lineStats = SLOCinLines(allLines);
				result[l] = lineStats;
			}
		}
	}
	return result;
}

/*************** Tests **********************/
test bool testSLOCFile() {
	loc file = |project://sqat-analysis/src/sqat/series1/testFiles/A1_test.java|;
	list[str] allLines = readFileLines(file);
	<linesOfCode, comments, blanks> = SLOCinLines(allLines);
	result = blanks == 8;
	result = result && (comments == 28);
	result = result && (linesOfCode == 24);
	return result;
}

test bool testSLOCEmpty() {
	lines = ["\n", "\n", "\n"];
	<linesOfCode, comments, blanks> = SLOCinLines(lines);
	result = blanks == 3;
	result = result && (comments == 0);
	result = result && (linesOfCode == 0);
	return result;
}

test bool testSLOCComment() {
	lines = ["/* this is\n", "* a really nice\n", "* multiline comment*/ \n"];
	<linesOfCode, comments, blanks> = SLOCinLines(lines);
	result = blanks == 0;
	result = result && (comments == 3);
	result = result && (linesOfCode == 0);
	return result;
}

test bool testSLOCLines() {
	lines = ["int x = 4;\n", "/* init variable y */ int y = 42;\n", " \n  "];
	<linesOfCode, comments, blanks> = SLOCinLines(lines);
	result = blanks == 1;
	result = result && (comments == 0);
	result = result && (linesOfCode == 2);
	return result;
}

test bool testSLOCLines2() {
	lines = ["int x = 4; /* var x */", "int y = 42; /* init variable y */", ""];
	<linesOfCode, comments, blanks> = SLOCinLines(lines);
	result = blanks == 1;
	result = result && (comments == 0);
	result = result && (linesOfCode == 2);
	return result;
}

/*************** End Tests **********************/
