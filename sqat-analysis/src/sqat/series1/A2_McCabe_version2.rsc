module sqat::series1::A2_McCabe_version2

import lang::java::jdt::m3::AST;
import analysis::m3::AST;
import Node;
import Prelude;
import util::ValueUI;
import IO;

/*

Construct a distribution of method cylcomatic complexity. 
(that is: a map[int, int] where the key is the McCabe complexity, and the value the frequency it occurs)


Questions:
- which method has the highest complexity (use the @src annotation to get a method's location)

- how does pacman fare w.r.t. the SIG maintainability McCabe thresholds?

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
set[Declaration] jpacmanASTs() = createAstsFromEclipseProject(|project://jpacman-framework|, true);
//Declaration testASTs() = createAstFromFile(|project://jpacman/src/main/java/nl/tudelft/jpacman/board/Square.java|, true);
Declaration testAST() = createAstFromFile(|project://sqat-analysis/src/sqat/series1/testFiles/Test.java|, true); 

alias CC = rel[loc method, int cc];
alias CCDist = map[int cc, int freq];

//public &T cast(type[&T] tp, value v) throws str {
//    if (&T tv := v)
//        return tv;
//    else
//        throw "cast failed";
//}

/* testfunctions */
test bool test01() = size(handleDeclaration(createAstFromFile(|project://sqat-analysis/src/sqat/series1/testFiles/Test.java|, true))) == 12;
test bool test02() = numberOfIfClauses(\infix(\booleanLiteral(true), "&&", \booleanLiteral(true))) == 2;

test bool javaTestFile() {

	Declaration d = createAstFromFile(|project://sqat-analysis/src/sqat/series1/testFiles/Test.java|, true);
	CC methods = handleDeclaration(d);
	//if (!test01) {
	//	return false;
	//}
	
	CCDist hist = ccDist(methods);
	
	CCDist histGood = (7:2, 1:1, 3:2, 2:1, 4:2, 5:2, 8:2);
	if (hist != histGood) {
		println("SumTing Wong");
		return false;
	}
	
	return true;
} 

//CCDist ccDist(CC cc);
//CC handleDeclaration(Declaration d);
//int calculateCC(Statement methodBody);
//int handleCondition(Expression e);

void main() {
	/*For Test.java*/
	set[Declaration] s = {testAST()};
	CC result = cc(s);
	
	/*For entire eclipse project*/
	//CC result = cc(jpacmanASTs());
	
	//println("\nNow we print result:");
	//println(result);
	print("BEGIN result:\n\n");
	for (m <- result) {
		println(m);
	}
	print("\nEND result");
	
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
			//operators += ((operator == "&" || operator == "|") ? 0 : 0);
		}
	}
	return clauses;
}