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

Declaration testASTs() = createAstFromFile(|project://jpacman-framework/src/main/java/nl/tudelft/jpacman/board/Square.java|, true); 
//Declaration testASTs() = createAstFromFile(|project://jpacman-framework/src/main/java/nl/tudelft/jpacman/Launcher.java|, true); 

alias CC = rel[loc method, int cc];
alias flowGraph = tuple[int N, int E, int P];

void main() {
	map[int, int] ccHist;
	CC relation;
	//print(CC);
	Declaration d = testASTs();
	loc l;
	flowGraph cycomp;
	//anno loc Declaration@src;
	//anno loc Declaration @ src;
	visit(d) {
		case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
			cycomp = getCC(impl);
			<nodes, edges, points> = cycomp;
			l = m.src;
			print(l);
			print("\t method == " + name + ", cc == ");
			println(cycomp);
			println(edges - nodes + 2 * points);
		
			//ccHist = addToHist(ccHist, cycomp);
			//CC += <l,cycomp>;
		}
		case \constructor(str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
			println("IF\'S CAN OCCUR IN CONSTRUCTOR?");
		}
	}
}

flowGraph handleIf(Statement ifStatement) {
	flowGraph result = <0, 0, 0>;
	switch(ifStatement) {
		case f:\if(Expression condition, Statement thenBranch): {
			result = addFlowGraph(getCC(thenBranch), <3, 3, 0>);
		}
		case f:\if(Expression condition, Statement thenBranch, Statement elseBranch): {
			result = addFlowGraph(getCC(thenBranch), getCC(elseBranch));
			result = addFlowGraph(result, <4, 4, 0>);
		}
	}
	print(result);
	return result;
}

flowGraph handleFor(Statement forBody) {
	flowGraph result = <3, 3, 0>;
	return addFlowGraph(result, getCC(forBody));
}

flowGraph addFlowGraph(flowGraph a, flowGraph b) {
	int n, e, p, n1, e1, p1;
	<n,e,p> = a;
	<n1, e1, p1> = b;
	return <n+n1, e+e1, p+p1>;
}

flowGraph getCC(Statement branch) {
	flowGraph total = <0, 0, 0>;
	flowGraph interim;
	
	
	visit(branch) {	
		case r:\return(): {
			total = addFlowGraph(total, <0, 0, 1>);
		}
		case r:\return(_): {
			total = addFlowGraph(total, <0, 0, 1>);
		}
		case f:\if(_, _): {
			total = addFlowGraph(total, handleIf(f));
		}
		case f:\if(_,  _, _): {
			total = addFlowGraph(total, handleIf(f));
		}
		case \for(list[Expression] initializers, Expression condition, list[Expression] updaters, Statement body): {
			total = addFlowGraph(total, handleFor(body));
		}
		case \for(list[Expression] initializers, list[Expression] updaters, Statement body): {
			total = addFlowGraph(total, handleFor(body));
		}
		case \foreach(Declaration parameter, Expression collection, Statement body): {
			total = addFlowGraph(total, handleFor(body));
    	}
		//case \switch(Expression expression, list[Statement] statements): {
		//	for(Statement s <- statements) {
		//		cc += getCC(s);
		//	}
		//	cc += 1;
		//}

		//case \while(Expression condition, Statement body): {
		//	cc += getCC(body);
		//	cc += 1;
		//}
		//case \do(Statement body, Expression condition): {
		//	cc += 1;
		//}
		//case \case(Expression expression): {			NOT SURE ABOUT THIS
		//	dosmth();
		//}
		//case \defaultCase(): {							AND THIS
		//	dosmth();
		//}
		//case \try(Statement body, list[Statement] catchClauses): {
		//	cc += getCC(body);
		//	for(Statement s <- catchClauses) {
		//		cc += getCC(s);
		//	}
		//		cc += 1;
		//}
		//case \try(Statement body, list[Statement] catchClauses, Statement \finally): {
		//	cc += getCC(body);
		//	cc += getCC(\finally);
		//	for(Statement s <- catchClauses) {
		//		cc += getCC(s);
		//		cc += 1;, 
		//	}
		//}
	}
	return total;
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
