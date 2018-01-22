module sqat::series1::avoidStarImport

import IO;
import ParseTree;
import String;
import Map;
import util::FileSystem;
import util::ResourceMarkers;

/*
 * Adds markers at locations where there are imports with stars
 * in them. This is useful in different editors. When an import
 * with a star occurs, a lot of files will be imported. This often
 * is not necessary will result in lots of unnecessary imports. 
 */

test bool testTestFile() {
	loc testFile = |project://sqat-analysis/src/sqat/series1/testFiles/A1_test.java|;
	<violations, warnings> = checkStyleStarImports(proj=testFile, printLocs=true);
	return size(violations) == 1;
}


//Star imports, maps a sourceLoc to a bool whether it is a "bad" line
alias SI = map[loc line, bool starImport];

//jpacman is default project
tuple[SI, set[Message]] checkStyleStarImports(loc proj = |project://jpacman-framework/src|, bool printLocs=false) {
	SI si = starImportLines(proj);
	if (printLocs) {
		println(si);
	}
	return <si, warningsForStarImports(si)>;
}

set[Message] warningsForStarImports(SI si) 
  = { warning("Line with a star import. Sure we need all of them?", l) | l <- si  };

// If it is an import statement that contains a "*", return true
bool isStarImport(str line) {
	line = trim(line);
	if (line[0..6] != "import") {
		return false;
	} else {
		return (/\*/ := line);
	}
}

//Map all lines to their sourceLoc and map that to a bool stating whether it is a starImport
SI linesToLocStarImportBool(list[str] lines, loc fileLoc) {
	SI result = ();
	int accum = 0;
	for (line <- lines) {
		result[fileLoc(accum, size(line), <0,0>, <0,0>)] = isStarImport(line);
		accum += size(line) + 1;
	}
	return result;
}

//For all files in project locate the starImports
SI starImportLines(loc project) {
  	FileSystem fs = crawl(project);
  	SI starImports = ();
  	top-down-break visit(fs) {
  		case f:file(loc filePath): {
  			if ((/\.java/ := filePath.path)) {
				allLines = readFileLines(filePath);
				lineImports = linesToLocStarImportBool(allLines, filePath);
				starImports += ( line: lineImports[line] | loc line <- lineImports, lineImports[line]);
			}
  		}
  	}
  	return starImports;
}
