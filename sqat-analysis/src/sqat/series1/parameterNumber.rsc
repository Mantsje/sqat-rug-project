module sqat::series1::parameterNumber

import IO;
import ParseTree;
import String;
import Map;
import Prelude;
import util::FileSystem;
import util::ResourceMarkers;
import lang::java::jdt::m3::AST;
import analysis::m3::AST;
import Type;
/*
 * Adds a marker at the top of the file indicating that the number
 * of methods exceeds a certain thresohold. To many methods indicates
 * a big class in which the possibility of distributing tasks exists.  
 */

test bool testTestFile() {
	loc testFile = |project://sqat-analysis/src/sqat/series1/testFiles/A1_test.java|;
	MP warnings = checkStyleParameterNumber(proj=testFile, threshold=7 , printLocs=true);
	return size(warnings) == 0;
}


//Star imports, maps a sourceLoc to a bool whether it is a "bad" line
alias MP = map[loc method, int parameters];

loc p = |project://jpacman/src|;

// jpacman is default project
MP checkStyleParameterNumber(loc proj = |project://jpacman/src|, int threshold = 7, bool printLocs=false) {
	MP mp = methodParameterNumber(proj, threshold);
	addMessageMarkers(warningsForParameterNumber(mp, threshold));
	if (printLocs) {
		println(mp);
	}
	return mp;
}

set[Message] warningsForParameterNumber(MP mp, int threshold) 
  = { warning(("To many parameters in this method. guideline: <threshold>."), l) | l <- mp};

//Locate all methdos in the file and return the locations in a list
MP methodParameters(loc file) {
	MP mp = ();
	Declaration d = createAstFromFile(file, true); 
	visit(d) {
		case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement body): {
			mp[m.src] = size(parameters);
		}
	}	
	return mp;
}

MP methodParameterNumber(loc project, int threshold) {
  	FileSystem fs = crawl(project);
  	MP longParameterListMethods = ();
  	top-down-break visit(fs) {
  		case f:file(loc filePath): {
  			if( (/\.java/ := filePath.path)) {
				allMethods = methodParameters(filePath);
				longParameterListMethods += (m:allMethods[m] | loc m <- allMethods, allMethods[m] > threshold);
			}
  		}
  	}
  	return longParameterListMethods;
}