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


set[Declaration] jpacmanASTs() = createAstsFromEclipseProject(|project://jpacman-framework|, true); 

//Declaration testASTs() = createAstFromFile(|project://jpacman-framework/src/main/java/nl/tudelft/jpacman/board/Square.java|, true); 
//Declaration testASTs() = createAstFromFile(|project://jpacman/src/main/java/nl/tudelft/jpacman/board/Square.java|, true);
Declaration testASTs() = createAstFromFile(|project://jpacman/Test.java|, true); 

alias CC = rel[loc method, int cc];

void main() {
	map[int, int] ccHist;
	CC relation;
	//print(CC);
	Declaration d = testASTs();
	loc l;
	int cycomp;
	//anno loc Declaration@src;
	//anno loc Declaration @ src;
	visit(d) {
		case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
			cycomp = getCC(impl);
			l = m.src;
			print(l);
			print("\t method == " + name + ", cc == ");
			println(cycomp);
		
			//ccHist = addToHist(ccHist, cycomp);
			//CC += <l,cycomp>;
		}
		case \constructor(str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
			println("IF\'S CAN OCCUR IN CONSTRUCTOR?");
		}
	}
}

int clauses(Expression e) {
	int andOperators = 0;
	visit(e) {
		case \infix(Expression lhs, str operator, Expression rhs) :{
			andOperators += ((operator == "AND" || operator == "&&") ? 1 : 0);
		}
		case \postfix(Expression operand, str operator) :{
			// Don't think this is necessary, but to keep it general..?
			andOperators += ((operator == "AND" || operator == "&&") ? 1 : 0);
		}
		case \prefix(str operator, Expression operand) :{
			// Don't think this is necessary, but to keep it general..?
			andOperators += ((operator == "AND" || operator == "&&") ? 1 : 0);
		}	
	}
	// number of clauses == number of AND operators + 1
	return 1 + andOperators;
}

int getCC(Statement branch) {
	int decisionPoints = 0;
	int exitPoints = 1;

	visit(branch) {
		case \if(Expression condition, Statement thenBranch) :{
			decisionPoints += clauses(condition);
		}	
		case \if(Expression condition, Statement thenBranch, Statement elseBranch) :{
			decisionPoints += clauses(condition);
		}	
		case \for(list[Expression] initializers, Expression condition, list[Expression] updaters, Statement body): {
			decisionPoints += clauses(condition);
		}
		case \for(list[Expression] initializers, list[Expression] updaters, Statement body): {
			decisionPoints += 1;
		}
		case \foreach(Declaration parameter, Expression collection, Statement body): {
			decisionPoints += 1;
		}
		case \return(Expression expression): {
			println("returnStatement");
		}
		case \return(): {
			println("returnStatement");
		}
	}
	return decisionPoints - exitPoints + 2;
}	

map[int, int] addToHist(map[int, int] hist, int key) {
	if (key notin hist) {
		hist[key] = 1;
	} else {
		hist[key] += 1;
	}
	return hist;
}

CC cc(set[Declaration] decls) {
  CC result = {};
  
  // to be done
  
  return result;
}

alias CCDist = map[int cc, int freq];

CCDist ccDist(CC cc) {
  // to be done
}
