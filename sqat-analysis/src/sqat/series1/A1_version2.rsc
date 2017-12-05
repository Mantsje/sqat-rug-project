module sqat::series1::A1_version2

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
- what is the biggest file in JPacman?							<|src/main/java/nl/tudelft/jpacman/level/Level.java|, 179>
- what is the total size of JPacman?							total size = 2458
- is JPacman large according to SIG maintainability?			No <<< 0-66 KLOC
- what is the ratio between actual code and test code size?		main = 1901, tests = 557

Sanity checks:
- write tests to ensure you are correctly skipping multi-line comments
- and to ensure that consecutive newlines are counted as one.
- compare you results to external tools sloc and/or cloc.pl

Bonus:
- write a hierarchical tree map visualization using vis::Figure and 
  vis::Render quickly see where the large files are. 
  (https://en.wikipedia.org/wiki/Treemapping) 

*/


alias SLOC = map[loc file, int sloc];

SLOC sloc(loc project) {
	SLOC result = ();
  	FileSystem fs = crawl(project);
	result = filterFiles(fs);
	
	return result;
}         

void main() {
	loc jpacman = |project://jpacman-framework/src|;
	//loc tests = |project://jpacman-framework/src/test|;
	//loc source = |project://jpacman-framework/src/main|;
	//loc singleFile = |project://jpacman-framework/src/test/java/nl/tudelft/jpacman/board/BasicUnit.java|;
	SLOC res = sloc(jpacman);
	for(f <- res) {
		print(f);
		print(" : ");
		println(res[f]);
	}
	println((0 | it + res[x]| x <- res));
}    

SLOC filterFiles(FileSystem fs) {
	SLOC result = ();
	//tuple [loc file, int SLOC] max = <|project://jpacman-framework|, 0>;
	//int totalSize = 0;
	//int filesSeen = 0;
	//int blankLines = 0;
	int nComments = 0;
	visit (fs) {
		case file(loc l): {
			if( (/\.java/ := l.path)) {
				allLines = readFileLines(l);
				lines = [ trim(x) | str x <- allLines, trim(x) != ""];
				lines2 = [x | str x <- lines, x[0..2] != "//"];
				inComment = false;
				linesOfCode = 0;
				for (line <- lines2) {
					//Is there an opening comment?
					if(!inComment && /\/\*/ := line) {
						if (/".*\/\*.*"/ := line) {
							linesOfCode += 1;
						} else {
							inComment = true;
							//Is there code before the opening of comment?
							if (/\S+\/\*/ := line) {
								linesOfCode += 1;
							} else {
								nComments += 1;
							}
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
				nComments += size(lines) - size(lines2);
				//filesSeen += 1;
				//blankLines += size(allLines) - size(lines);
				//totalSize += linesOfCode;
				result[l] = linesOfCode;
			}
		}
	}
	//println(max);
	//print("nFiles = ");
	//println(filesSeen);
	//print("blank Lines = ");
	//println(blankLines);
	//print("comment Lines = ");
	//println(nComments);
	//print("total SLOC = ");
	//println(totalSize);
	//println("");
	return result;
}
