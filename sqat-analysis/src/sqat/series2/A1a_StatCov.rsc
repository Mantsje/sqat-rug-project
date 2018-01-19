module sqat::series2::A1a_StatCov2

import lang::java::jdt::m3::Core;
import IO;
import String;
import Set;

/*

Implement static code coverage metrics by Alves & Visser 
(https://www.sig.eu/en/about-sig/publications/static-estimation-test-coverage)


The relevant base data types provided by M3 can be found here:

- module analysis::m3::Core:

rel[loc name, loc src]        M3.declarations;            // maps declarations to where they are declared. contains any kind of data or type or code declaration (classes, fields, methods, variables, etc. etc.)
rel[loc name, TypeSymbol typ] M3.types;                   // assigns types to declared source code artifacts
rel[loc src, loc name]        M3.uses;                    // maps source locations of usages to the respective declarations
rel[loc from, loc to]         M3.containment;             // what is logically contained in what else (not necessarily physically, but usually also)
list[Message]                 M3.messages;                // error messages and warnings produced while constructing a single m3 model
rel[str simpleName, loc qualifiedName]  M3.names;         // convenience mapping from logical names to end-user readable (GUI) names, and vice versa
rel[loc definition, loc comments]       M3.documentation; // comments and javadoc attached to declared things
rel[loc definition, Modifier modifier] M3.modifiers;      // modifiers associated with declared things

- module  lang::java::m3::Core:

rel[loc from, loc to] M3.extends;            // classes extending classes and interfaces extending interfaces
rel[loc from, loc to] M3.implements;         // classes implementing interfaces
rel[loc from, loc to] M3.methodInvocation;   // methods calling each other (including constructors)
rel[loc from, loc to] M3.fieldAccess;        // code using data (like fields)
rel[loc from, loc to] M3.typeDependency;     // using a type literal in some code (types of variables, annotations)
rel[loc from, loc to] M3.methodOverrides;    // which method override which other methods
rel[loc declaration, loc annotation] M3.annotations;

Tips
- encode (labeled) graphs as ternary relations: rel[Node,Label,Node]
- define a data type for node types and edge types (labels) 
- use the solve statement to implement your own (custom) transitive closure for reachability.

Questions:
- what methods are not covered at all?
See print statement in main
- how do your results compare to the jpacman results in the paper? Has jpacman improved?
In the paper it was a lot higher, however also Clover gives result that are closer to ours than to the ones in the paper.
So apparantly the queality and covered parts of testing has decreased over the years.
- use a third-party coverage tool (e.g. Clover) to compare your results to (explain differences)
Differences come from of course being able to actually check which methods are called (no virtual call edges and such).
Also it is a much more fine tuned tool which does more proper analyzing.
There are some cases that could slip through the simple boolean checks we perform to determine what type of code we're dealing with.
(java standard, junit, productionCode, testCode, etc)

import sqat::series2::A1a_StatCov;
main();

*/

alias Cov = map[loc, tuple[int, int]];

set[loc] allMethods;
set[loc] allClasses;
set[loc] allInterfaces;
set[loc] allPackages;

M3 jpacmanM3() = createM3FromEclipseProject(|project://jpacman-framework|);

bool isClass(loc src) 		 = src.scheme == "java+class";
bool isCUnit(loc src) 		 = src.scheme == "java+compilationUnit";
bool isPackage(loc src) 	 = src.scheme == "java+package";
bool isInterface(loc src) 	 = src.scheme == "java+interface";
bool isMethod(loc src) 		 = src.scheme == "java+method" || src.scheme == "java+constructor";
bool isJavaStandard(loc src) = startsWith(src.path, "/java");
bool isTestCode(loc src) 	 = contains(src.path, "/test/");
bool isProductionCode(loc src) = !isTestCode(src) &&  contains(src.path, "jpacman") && !isJavaStandard(src);
bool isTestMethod(set[loc] annotations) = |java+interface:///org/junit| in { a.parent | a <- annotations };

set[loc] getClasses(M3 project)    	= {decl[0] | decl <- project.declarations, isClass(decl[0]), 	!isTestCode(decl[1])};
set[loc] getPackages(M3 project)    = {decl[0] | decl <- project.declarations, isPackage(decl[0]),   !isTestCode(decl[1])};
set[loc] getInterfaces(M3 project)  = {decl[0] | decl <- project.declarations, isInterface(decl[0]), !isTestCode(decl[1])};
set[loc] getMethods(M3 project)     = {decl[0] | decl <- project.declarations, isMethod(decl[0]),    isProductionCode(decl[1])};
set[loc] getTestMethods(M3 project) = {meth[0] | meth <- project.declarations, isTestMethod(project.annotations[meth[0]])};

set[loc] getMethodsOfLoc(M3 project, loc src) {
	set[loc] methods = { m | m <- project.containment[src], m in getMethods(project)};
	set[loc] allMethods = getMethods(project);
	solve(methods) {
		for (meth <- methods) {
			methods += {m | m <- project.methodOverrides[meth], m in allMethods};
		}
	}
	return methods;
}

tuple[loc, set[loc]] methodsOfClass(M3 project, loc class) = <class, getMethodsOfLoc(project, class)>;

set[loc] getContainedPackages(M3 project, loc package) = { p | p <- project.containment[package], p in getPackages(project) };
tuple[loc, set[loc]] transClosPackage(M3 project, loc package) {
	set[loc] result = {package};		
	solve(result) {
		for (p <- result) {
			result += getContainedPackages(project, p);
		}
	}
	result -= package;
	return <package, result>;
}

//Find all compilation units contained in package and get all interfaces and classes contained in those
tuple[loc, set[loc]] classesAndInterfacesOfPackage(M3 project, loc package) {
	set[loc] result = ( {} | it + s | s <- { project.containment[CI] | CI <- project.containment[package], isCUnit(CI)} );
	result = {c | c <- result, c in allClasses || c in allInterfaces };
	return <package, result>;
}

set[loc] getCoveredMethods(M3 project) {
	set[loc] testMethods = getTestMethods(project);
	set[loc] testedMethods = getTestMethods(project);
	solve(testedMethods) {
		temp = { {q | q <- project.methodInvocation[m], isProductionCode(q)} | m <- testedMethods};
		testedMethods += ({} | it + s | s <- temp);
	}
	return testedMethods - testMethods;
}

/* ********** ********** result related ********** ********** */

void printNonCoveredMethods(set[loc] tested, set[loc] allMethods) 
	{ for(m <- (allMethods - tested)) println(m); }

void printTotalCoverage(set[loc] testedMethods, set[loc] allMethods) 
	{ println("Total coverage: " + makePercentage(size(testedMethods), size(allMethods))); }

void printCoveragePerPackage(Cov packageCoverage) 
	{ for (p <- packageCoverage) println("<p> : " + makePercentage(packageCoverage[p][0], packageCoverage[p][1]));  }

void printCoveragePerClass(Cov classCoverage) 
	{ for (c <- classCoverage) println("<c> : " + makePercentage(classCoverage[c][0], classCoverage[c][1]));  }


tuple[loc, tuple[int, int]] getCoverageForClass(M3 project, loc class, set[loc] tested) {
	<class, meths> = methodsOfClass(project, class); 
	int covered = size({meth | meth <- meths, meth in tested});
	return <class, <covered, size(meths)>>;
}

Cov getCoveragePerClassAndInterface(M3 project, set[loc] tested) {
	Cov result = (); 
	for (c <- (allClasses + allInterfaces)) {
		out = getCoverageForClass(project, c, tested);
		result[out[0]] = out[1];
	}
	return result;
}

tuple[loc, tuple[int, int]] getCoverageForPackage(M3 project, loc package, Cov classCoverage) {
	<package, cis> = classesAndInterfacesOfPackage(project, package);
	tuple[loc, tuple[int, int]] result = <package, <0, 0>>;
	for(c <- cis) {
		temp = classCoverage[c];
		result[1] = <result[1][0] + temp[0], result[1][1] + temp[1]>; 
	}
	println(result);
	return result;
}


Cov getCoveragePerPackage(M3 project, Cov coveragePerClass) {
	Cov result = (); 
	for (p <- allPackages) {
		out = getCoverageForPackage(project, p, coveragePerClass);
		result[out[0]] = out[1];
	}
	return result;
}


str makePercentage(num a, num b) = b == 0 ? "100%" : "<(a / b) * 100>%";

void main() {
	M3 project = jpacmanM3();
	allMethods = getMethods(project);
	allClasses = getClasses(project);
	allInterfaces = getInterfaces(project);
	allPackages = getPackages(project);	
	set[loc] coveredMethods = getCoveredMethods(project);
	
	Cov classCoverage = getCoveragePerClassAndInterface(project, coveredMethods);
	Cov packageCoverage = getCoveragePerPackage(project, classCoverage);
	//printCoveragePerClass(classCoverage);
	//printCoveragePerPackage(packageCoverage);
	//printNonCoveredMethods(coveredMethods, allMethods);
	printTotalCoverage(coveredMethods, allMethods);	
}