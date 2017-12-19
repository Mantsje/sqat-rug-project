module sqat::series1::A2_McCabe_version2

import lang::java::jdt::m3::AST;
import analysis::m3::AST;
import Prelude;
import analysis::statistics::Correlation;

/*
Construct a distribution of method cylcomatic complexity. 
(that is: a map[int, int] where the key is the McCabe complexity, and the value the frequency it occurs)


Questions:
- which method has the highest complexity (use the @src annotation to get a method's location)
A: |project://jpacman/src/main/java/nl/tudelft/jpacman/npc/ghost/Inky.java|(2255,2267,<68,1>,<131,17>)

- how does pacman fare w.r.t. the SIG maintainability McCabe thresholds?
A: The method with the highest complexity is 8. According to SIG, a cc of 1-10 has a risk evaluation of: simple, without much risk

- is code size correlated with McCabe in this case (use functions in analysis::statistics::Correlation to find out)? 
  (Background: Davy Landman, Alexander Serebrenik, Eric Bouwers and Jurgen J. Vinju. Empirical analysis 
  of the relationship between CC and SLOC in a large corpus of Java methods 
  and C functions Journal of Software: Evolution and Process. 2016. 
  http://homepages.cwi.nl/~jurgenv/papers/JSEP-2015.pdf)
  
- what if you separate out the test sources?

Tips: 
- the AST data type can be found in module lang::java::m3::AST
- use visit to quickly find methods in Declaration ASTs
- compute McCabe by matching on AST nodes

Sanity checks
- write tests to check your implementation of McCabe

Bonus
- write visualization using vis::Figure and vis::Render to render a histogram.
constructor
*/

/* jpacman-framework statements */
//set[Declaration] jpacmanASTs() = createAstsFromEclipseProject(|project://jpacman-framework|, true); 
//Declaration testASTs() = createAstFromFile(|project://jpacman-framework/src/main/java/nl/tudelft/jpacman/board/Square.java|, true); 

/* jpacman statements */
set[Declaration] jpacmanASTs() = createAstsFromEclipseProject(|project://jpacman|, true);
set[Declaration] jpacmanNoTestsASTs() = createAstsFromEclipseProject(|project://jpacman/src/main|, true);
Declaration testAST() = createAstFromFile(|project://sqat-analysis/src/sqat/series1/testFiles/Test.java|, true); 

alias CC = rel[loc method, int cc];
alias CCDist = map[int cc, int freq];

/* BEGIN testfunctions && variables */
Declaration d1 = \import("8");

Expression e1 = \infix(\booleanLiteral(true), "&&", \booleanLiteral(true));
Expression e2 = \infix(e1, "||", \booleanLiteral(true));
Expression e3 = \infix(e1, "||", e2);

Statement s1 = \continue();
Statement s2 = \foreach(d1, e1, s1);
Statement s3 = \for([], e1, [], s1);
Statement s4 = \if(e1, s1);
Statement s5 = \if(e1, s1, s1);
Statement s6 = \switch(\null(), [\case(\null()), \case(\null()), \case(\null()), \case(\null()), \defaultCase()]);
Statement s7 = \try(s1, [s1,s1,s1,s1,s1]);

test bool test01() = size(handleDeclaration(createAstFromFile(|project://sqat-analysis/src/sqat/series1/testFiles/Test.java|, true))) == 12;
test bool test02() = numberOfIfClauses(e1) == 2;
test bool test03() = numberOfIfClauses(e2) == 3;
test bool test04() = numberOfIfClauses(e3) == 5;

test bool test05() = calculateCC(s2) == 2;				// std 1 + (foreach)=1;
test bool test06() = calculateCC(s3) == 3;				// std 1 + numberOfIfClauses(e1) of for;
test bool test07() = calculateCC(s4) == 3;				// std 1 + numberOfIfClauses(e1) of if;
test bool test08() = calculateCC(s4) == calculateCC(s5);	// elseBranch does not make any difference for cc of if
test bool test09() = calculateCC(s6) == 6;				// std 1 + switch statement with 5 cases;
test bool test10() = calculateCC(s7) == 7;				// std 1 + try + number of catch clauses (5)

test bool javaTestFile() {
	/* Using the file Test.java */
	Declaration d = createAstFromFile(|project://sqat-analysis/src/sqat/series1/testFiles/Test.java|, true);
	CC methods = handleDeclaration(d);
	if (!test01()) return false;
	
	CCDist calculatedHist = ccDist(methods);
	CCDist correctHist = (7:2, 1:1, 3:2, 2:1, 4:2, 5:2, 8:2);
	return calculatedHist == correctHist;
} 

/* END testfunctions && variables */

void main() {
	//CC result = cc(jpacmanASTs());
	CC result = cc(jpacmanNoTestsASTs());
	
	//print("BEGIN result:\n\n");
	//for (m <- result) {
	//	println(m);
	//}
	//print("\nEND result");
	
	CCDist hist = ccDist(result);
	println("\nThe histogram:");
	println(hist);
	
	maxCC = max(hist<0>);
	
	for (<l, cirComp> <- result) {
		if (cirComp == maxCC) {
			print("cc of ");
			print(maxCC);
			print(" at location:  ");
			println(l);
		}
	}
	
	//println("\nmore Results:");
	// Functions in analysis::statistics::Correlation, to calculate correlation
	//println(covariance(lrel[num x,num y] values));
	//println(PearsonsCorrelation);
	//println(PearsonsCorrelationPValues(lrel[num x,num y] values));
	//println(PearsonsCorrelationStandardErrors(lrel[num x,num y] values));
	//println(SpearmansCorrelation(lrel[num x,num y] values));
}

CC cc(set[Declaration] decls) {
	CC result = {};
	int circomp;
	loc l;
	for (Declaration d <- decls) {
		x = handleDeclaration(d);
		result = result + x;
	}
	
	// result is a CC (rel[loc method, int cc]) with every method with the corresponding circular complexity
	return result;
}

// Make a histogram of the CC (rel[loc method, int cc]), we get a CCDist = map[int cc, int freq].
// cc is the key and the frequency it occurs 
CCDist ccDist(CC cc) {
	CCDist hist = ();
	for (<l,cirComp> <- cc) {
		if (cirComp notin hist) {
			hist[cirComp] = 1;
		} else {
			hist[cirComp] += 1;
		}
	}
	return hist;
}

// Calculate the circular complexity for every method in the declaration
// return a CC (rel[loc method, int cc])
CC handleDeclaration(Declaration d) {
	CC locCC = {};
	loc l;
	int cirComp = 0;
	visit(d) {
		case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement body): {
			cirComp = calculateCC(body);
			l = m.src;
			locCC = locCC + <l,cirComp>;
		}
		case c:\constructor(str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
			cirComp = calculateCC(impl);
			l = c.src;
			locCC = locCC + <l,cirComp>;
		}
	}
	return locCC;
}

// calculate and return the cc for the given Statement
int calculateCC(Statement methodBody) {
	int decisionPoints = 1; // std cc of 1

	visit(methodBody) {
		case \if(Expression condition, Statement thenBranch) :{
			// An if case adds one for every contition it tests (1 + shortcircuitingbinaryoperators)
			// The function takes care of the +1
			decisionPoints += numberOfIfClauses(condition);
		}	
		case \if(Expression condition, Statement thenBranch, Statement elseBranch) :{
			// else is linear and won't add anything to the cc
			decisionPoints += numberOfIfClauses(condition);
		}	
		case \case(Expression expression) : {
			// each case of an switch will add 1 to the cc 
			decisionPoints += 1;
		}
		case \defaultCase() : {
			// default is also a case of the switch 
			decisionPoints += 1;
		}
		case \for(list[Expression] initializers, Expression condition, list[Expression] updaters, Statement body): {
			// A for loop with conditions results in 1 + shortcircuitingbinaryoperators
			decisionPoints += numberOfIfClauses(condition);
		}
		case \for(list[Expression] initializers, list[Expression] updaters, Statement body): {
			// A for loop without conditions adds 1 to the cc
			decisionPoints += 1;
		}
		case \foreach(Declaration parameter, Expression collection, Statement body): {
			decisionPoints += 1;
		}
		case \while(Expression condition, Statement body) : {
			// A while loop adds one for every contition it tests (1 + shortcircuitingbinaryoperators)
			decisionPoints += numberOfIfClauses(condition);
		}
		case \do(Statement body, Expression condition) : {
			// A while loop adds one for every contition it tests (1 + shortcircuitingbinaryoperators)	
			decisionPoints += numberOfIfClauses(condition);
		}
	    	case \try(Statement body, list[Statement] catchClauses) : {
	    		// If !{codeblock} do applicable catches
	    		// codeblock can be seen as condition for executing catches	    		
			decisionPoints += 1 + size(catchClauses);;
	    	}
	    	case \try(Statement body, list[Statement] catchClauses, Statement \finally) : {
	    		// \finally is always executed, so no increase in complexity
			decisionPoints += 1 + size(catchClauses);
	    	}                                        
	}
	return decisionPoints;
}

int numberOfIfClauses(Expression e) {
	int clauses = 1;
	visit(e) {
		case \infix(Expression lhs, str operator, Expression rhs) :{
			clauses += ((operator == "&&" || operator == "||") ? 1 : 0);
		}
	}
	return clauses;
}