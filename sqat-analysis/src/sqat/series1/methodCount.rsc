module sqat::series1::avoidStarImport

import IO;
import ParseTree;
import String;
import Map;
import Prelude;
import util::FileSystem;
import lang::java::jdt::m3::AST;
import analysis::m3::AST;

/*
 * Adds a marker at the top of the file indicating that the number
 * of methods exceeds a certain thresohold. To many methods indicates
 * a big class in which the possibility of distributing tasks exists.  
 */

test bool testTestFile() {
	loc testFile = |project://sqat-analysis/src/sqat/series1/testFiles/A1_test.java|;
	SI warnings = checkStarImports(proj=testFile, printLocs=true);
	return size(warnings) == 1;
}


//Star imports, maps a sourceLoc to a bool whether it is a "bad" line
alias CM = map[loc class, List[loc] methods];

//jpacman is default project
SI checkStyleNumberOfMethods(loc proj = |project://jpacman-framework/src|, bool printLocs=false) {
	SI si = starImportLines(proj);
	addMessageMarkers(warningsForStarImports(si));
	if (printLocs) {
		println(si);
	}
	return si;
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

//Locate all methdos in the file and return gthe locations in a list
List[loc] retrieveMethodLocations(loc file) {
	List methods = ();
	Declaration d = createAstFromFile(file, true); 
	loc l;
	visit(d) {
		case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement body): {
			methods += m.src;
		}
	}
	
	return methods;
}

SI linesToLocStarImportBool(list[str] lines, loc fileLoc) {
	SI result = ();
	int accum = 0;
	for (line <- lines) {
		result[fileLoc(accum, size(line), <0,0>, <0,0>)] = isStarImport(line);
		accum += size(line);
	}
	return result;
}

// For all files in project locate the single line curly braces
List[loc] methodLocations(loc project) {
  	FileSystem fs = crawl(project);
  	top-down-break visit(fs) {
  		case f:file(loc filePath): {
  			if ((/\.java/ := filePath.path)) {
  				println(filePath.path);
  				List methods = retrieveMethods(filePath);
			}
  		}
  	}
  	return methods;
}
