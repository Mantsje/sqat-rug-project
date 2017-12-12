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
set[Declaration] jpacmanASTs() = createAstsFromEclipseProject(|project://jpacman-framework|, true); 
Declaration testASTs() = createAstFromFile(|project://jpacman-framework/src/main/java/nl/tudelft/jpacman/board/Square.java|, true); 

/* jpacman statements */
//set[Declaration] jpacmanASTs() = createAstsFromEclipseProject(|project://jpacman-framework|, true);
//Declaration testASTs() = createAstFromFile(|project://jpacman/src/main/java/nl/tudelft/jpacman/board/Square.java|, true);
//Declaration testASTs() = createAstFromFile(|project://jpacman/Test.java|, true); 

alias CC = rel[loc method, int cc];

void main() {
	/*For Test.java*/
	//set[Declaration] s = {testASTs()};
	//CC result = cc(s);
	
	/*For entire eclipse project*/
	CC result = cc(jpacmanASTs());
	
	//println("\nNow we print result:");
	//println(result);
	
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
		x = doDeclaration(d);
		result = result + x;
	}
	
	// result is a CC (rel[loc method, int cc]) with every method with the accompanied circular complexity
	return result;
}

map[int, int] addToHist(map[int, int] hist, int key) {
	if (key notin hist) {
		hist[key] = 1;
	} else {
		hist[key] += 1;
	}
	return hist;
}

alias CCDist = map[int cc, int freq];

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

CC doDeclaration(Declaration d) {
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
	int decisionPoints = 0;
	int exitPoints = 1;

	visit(methodBody) {
		case \if(Expression condition, Statement thenBranch) :{
			decisionPoints += 1 + handleCondition(condition);
		}	
		case \if(Expression condition, Statement thenBranch, Statement elseBranch) :{
			decisionPoints += 1 + handleCondition(condition);
		}	
		case \case(Expression expression) : {
			decisionPoints += 1;
		}
		case \defaultCase() : {
			decisionPoints += 1;
		}
		case \for(list[Expression] initializers, Expression condition, list[Expression] updaters, Statement body): {
			decisionPoints += 1 + handleCondition(condition);
		}
		case \for(list[Expression] initializers, list[Expression] updaters, Statement body): {
			decisionPoints += 1;
		}
		case \foreach(Declaration parameter, Expression collection, Statement body): {
			decisionPoints += 1;
		}
		case \while(Expression condition, Statement body) : {
			decisionPoints += 1 + handleCondition(condition);
		}
		case \do(Statement body, Expression condition) : {
			decisionPoints += 1 + handleCondition(condition);
		}
    	case \try(Statement body, list[Statement] catchClauses) : {
			decisionPoints += 1;
    	}
    	case \try(Statement body, list[Statement] catchClauses, Statement \finally) : {
			decisionPoints += 2;
    	}                                        
    	case \catch(Declaration exception, Statement body) : {
			decisionPoints += 1;
    	}
	}
	return decisionPoints - exitPoints + 2;
}

int handleCondition(Expression e) {
	int operators = 0;
	visit(e) {
		case \infix(Expression lhs, str operator, Expression rhs) :{
			operators += ((operator == "&&" || operator == "||") ? 2 : 0);
			//operators += ((operator == "&" || operator == "|") ? 0 : 0);
		}
		case \postfix(Expression operand, str operator) :{
			// Don't think this is necessary, but to keep it general..?
			operators += ((operator == "&&" || operator == "||") ? 2 : 0);
		}
		case \prefix(str operator, Expression operand) :{
			// Don't think this is necessary, but to keep it general..?
			operators += ((operator == "&&" || operator == "||") ? 2 : 0);
		}	
	}
	return operators;
}