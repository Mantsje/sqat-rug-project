module sqat::series1::customStyle

import IO;
import ParseTree;
import String;
import Map;
import util::FileSystem;
import util::ResourceMarkers;



test bool testTestFile() {
	loc testFile = |project://sqat-analysis/src/sqat/series1/testFiles/A1_test.java|;
	BS bad = checkStyleBraces(proj=testFile, printLocs=true);
	return size(bad) == 1;
}


//Bracket singles, maps a sourceLoc to a bool whether it is a "bad" line
alias BS = map[loc line, bool singleBrace];

//jpacman is default project
BS checkStyleBraces(loc proj = |project://jpacman-framework/src|, bool printLocs=false) {
	BS bs = singleBracketLines(proj);
	addMessageMarkers(warningsForSingleBraces(bs));
	if(printLocs) {
		println(bs);
	}
	return bs;
}

set[Message] warningsForSingleBraces(BS bs) 
  = { warning("Line with just an \"{\", please move back up", l) | l <- bs  };

//Map all lines to their sourceLoc and map that to a bool stating whether it is just a curly brace
BS linesToLocBraceBool(list[str] lines, loc fileLoc) {
	BS res = ();
	int accum = 0;
	for (line <- lines) {
		res[fileLoc(accum, size(line), <0,0>, <0,0>)] = (trim(line) == "{");		
		accum += size(line) + 1;	//Make up for deletion of \n
	}
	return res;
}

//For all files in project locate the single line curly braces
BS singleBracketLines(loc project) {
  	FileSystem fs = crawl(project);
  	BS singleBraces = ();
  	top-down-break visit(fs) {
  		case f:file(loc filePath): {
  			if( (/\.java/ := filePath.path)) {
				allLines = readFileLines(filePath);
				lineBraces = linesToLocBraceBool(allLines, filePath);
				singleBraces += ( line: lineBraces[line] | loc line <- lineBraces, lineBraces[line]);
			}
  		}
  	}
  	return singleBraces;
}    