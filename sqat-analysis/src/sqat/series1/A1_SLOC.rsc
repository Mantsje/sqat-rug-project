module sqat::series1::A1_SLOC

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
  return result;
}         

void main() {
	loc jpacman = |project://jpacman-framework/src|;
	FileSystem fs = crawl(jpacman);
	filterFiles(fs);
	
	loc tests = |project://jpacman-framework/src/test|;
	FileSystem fs_tests = crawl(tests);
	filterFiles(fs_tests);
	
	loc source = |project://jpacman-framework/src/main|;
	FileSystem fs_source = crawl(source);
	filterFiles(fs_source);

	return;
}    

void filterFiles(FileSystem fs) {
	tuple [loc file, int SLOC] max = <|project://jpacman-framework|, 0>;
	int totalSize = 0;
	int filesSeen = 0;
	int blankLines = 0;
	int nComments = 0;
	visit (fs) {
		case file(loc l): {
			if( (/\.java/ := l.path)) {
				allLines = readFileLines(l);
				lines = [ trim(x) | str x <- allLines, trim(x) != ""];
				lines2 = [x | str x <- lines, x[0..2] != "//"];
				str fullFile = intercalate("\n", lines2) + "\n";
				int SLOC = SLOCinFile(fullFile);
				if(SLOC > max.SLOC) {
					max = <l, SLOC>;
				}
				totalSize += SLOC;
				filesSeen += 1;
				blankLines += size(allLines) - size(lines);
				nComments += size(lines) - SLOC ;
			}
		}
	}
	println(max);
	print("nFiles = ");
	println(filesSeen);
	print("blank Lines = ");
	println(blankLines);
	print("comment Lines = ");
	println(nComments);
	print("total SLOC = ");
	println(totalSize);
	println("");
}

int SLOCinFile(str f) {
	int SLOC = 0;
	comment = false;
	inString = false;
	for (int ind <- [0..size(f)]) {
		if (!comment && f[ind] == "\"") {
			inString = !inString;
		} else if (!comment && !inString && f[ind..ind+2] == "/*") {
			if (f[ind-1] != "\n") {
				SLOC += 1;
			}
			ind += 1;
			comment = true;
		} else if (comment && !inString && f[ind..ind+2] == "*/") {
			if (f[ind+2] == "\n") {
				SLOC -= 1;
			}
			ind += 1;
			comment = false;
		} else if (comment || inString) {
			continue;
		} else if (f[ind] == "\n") {
			SLOC += 1;
		} 
	}
	return SLOC;
}
