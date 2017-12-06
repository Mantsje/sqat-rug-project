module sqat::series1::A2_McCabe

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
Declaration testASTs() = createAstFromFile(|project://jpacman/src/main/java/nl/tudelft/jpacman/Launcher.java|, true); 

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
			if (cycomp > 1) {
				print(l);
				print("\t method == " + name + ", cc == ");
				println(cycomp);
			}
			//ccHist = addToHist(ccHist, cycomp);
			//CC += <l,cycomp>;
		}
		case \constructor(str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
			println("IF\'S CAN OCCUR IN CONSTRUCTOR?");
		}
	}
}

int getCC(Statement branch) {
	int cc = 1;

	visit(branch) {
		case \if(Expression condition, Statement thenBranch): {
			cc += getCC(thenBranch);
			cc += 1;
		}
		case \if(Expression condition, Statement thenBranch, Statement elseBranch): {
			cc += getCC(thenBranch);
			cc += getCC(elseBranch);
			cc += 1;
		}		
		case \switch(Expression expression, list[Statement] statements): {
			for(Statement s <- statements) {
				cc += getCC(s);
			}
			cc += 1;
		}
		case \do(Statement body, Expression condition): {
			cc += 1;
		}
		case \while(Expression condition, Statement body): {
			cc += getCC(body);
			cc += 1;
		}
		//case \case(Expression expression): {			NOT SURE ABOUT THIS
		//	dosmth();
		//}
		//case \defaultCase(): {							AND THIS
		//	dosmth();
		//}
		case \try(Statement body, list[Statement] catchClauses): {
			cc += getCC(body);
			for(Statement s <- catchClauses) {
				cc += getCC(s);
			}
				cc += 1;
		}
		case \try(Statement body, list[Statement] catchClauses, Statement \finally): {
			cc += getCC(body);
			cc += getCC(\finally);
			for(Statement s <- catchClauses) {
				cc += getCC(s);
				cc += 1;
			}
		}
	}
	return cc;
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
