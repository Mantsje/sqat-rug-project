module sqat::series1::longLines

import IO;
import ParseTree;
import String;
import Map;
import util::FileSystem;
import util::ResourceMarkers;

/*
*	Adds markers at locations where lines exceed some
* 	threshold line size. This is useful in different editors
*	When files become too long they get hard to read and
* 	this should be prevented. This is also the reason that
* 	whitespace is not ignored. This tributes to the readability and
*	is therefore considered. The file extension can easily 
*	be changed to something else in longLines()
*/

test bool testTestFile() {
	loc testFile = |project://sqat-analysis/src/sqat/series1/testFiles/A1_test.java|;
	LL bad = checkStyleLongLines(proj=testFile, threshold=80, printLines=true);
	return size(bad) == 1;
}


alias LL = map[loc line, int size];

//jpacman is default project and default threshold is 80
LL checkStyleLongLines(loc proj = |project://jpacman-framework/src|, int threshold=80, bool printLines=false) {
	LL longLineLocs = longLines(proj, threshold);
	addMessageMarkers(warningsForLongLines(longLineLocs, threshold));
	if (printLines) {
		println(longLineLocs);
	}
	return longLineLocs;
}

set[Message] warningsForLongLines(LL ls, int threshold) 
  = { warning("Long line! len=" + "<ls[l]>" + " \> " + "<threshold>", l) | l <- ls};
  
  
//Map all lines in a file to a sourceLoc and map that loc to the lineSize
LL linesToLocSize(list[str] lines, loc fileLoc) {
	LL res = ();
	int accum = 0;
	for (line <- lines) {
		res[fileLoc(accum,size(line),<0,0>,<0,0>)] = size(line);		
		accum += size(line) + 1;	//Make up for deletion of \n
	}
	return res;
}

//traverse all files in the project and if extension matches filter all lines that are too long
LL longLines(loc project, int threshold) {
  	FileSystem fs = crawl(project);
  	LL longLines = ();
  	top-down-break visit(fs) {
  		case f:file(loc filePath): {
  			if( (/\.java/ := filePath.path)) {
				allLines = readFileLines(filePath);
				lineSize = linesToLocSize(allLines, filePath);
				longLines += (line:lineSize[line] | loc line <- lineSize, lineSize[line] > threshold);
			}
  		}
  	}
  	return longLines;
}