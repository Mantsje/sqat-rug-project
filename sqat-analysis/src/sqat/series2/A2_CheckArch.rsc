module sqat::series2::A2_CheckArch

import sqat::series2::Dicto;
import lang::java::jdt::m3::Core;
import Message;
import ParseTree;
import IO;
import String;
import Set;
import ParseTree;

/*

This assignment has two parts:
- write a dicto file (see example.dicto for an example)
  containing 3 or more architectural rules for Pacman
  
- write an evaluator for the Dicto language that checks for
  violations of these rules. 

Part 1  

An example is: ensure that the game logic component does not 
depend on the GUI subsystem. Another example could relate to
the proper use of factories.   

Make sure that at least one of them is violated (perhaps by
first introducing the violation).

Explain why your rule encodes "good" design.
  
Rule 1:
The package nl.tudelft.jpacman.game should not use features of the package ui, because game should be a seperate thing that is
observed. This means it cannot import the package UI.
Rule 2:
The Game must depend on a level. When a new game is started, it should in fact start a new level. The game really is the
connector between a player and a level. A game with only a player and no level makes no sense. This means the game.start()
should call the level.start(). 
Rule 3:
The ghosts Pinky, Clyde, Blinky and Inky must inherit from ghost, since they are all ghosts. They also cannot inherit from each other.
  
Part 2:  
 
Complete the body of this function to check a Dicto rule
against the information on the M3 model (which will come
from the pacman project). 

A simple way to get started is to pattern match on variants
of the rules, like so:

switch (rule) {
  case (Rule)`<Entity e1> cannot depend <Entity e2>`: ...
  case (Rule)`<Entity e1> must invoke <Entity e2>`: ...
  ....
}

Implement each specific check for each case in a separate function.
If there's a violation, produce an error in the `msgs` set.  
Later on you can factor out commonality between rules if needed.

The messages you produce will be automatically marked in the Java
file editors of Eclipse (see Plugin.rsc for how it works).

Tip:
- for info on M3 see series2/A1a_StatCov.rsc.

Questions
- how would you test your evaluator of Dicto rules? (sketch a design)
A:	We would create a testproject. This project does not have to be big, but it does need to have at least two packages
	of which one package has multiple java files, so that inheritance can be simulated. Also there should be made sure that
	at least one method refers to another method. 
	
- come up with 3 rule types that are not currently supported by this version
  of Dicto (and explain why you'd need them). 
A:	* The 'can only' modality is now implemented in a way that it can only have 1 instance. One might be able to check whether
	a class can only import multiple specific packages, instead of only being able to import one specific package.  
  	* The 'invoke' modality is now implemented in a way that the check is whether a name of a method is entailed in the
	invoked methods. This neglects the parameterlists. One might be able to narrow the specification of which method with the
	parameters ... are called.
	* 
A:
*/

loc getPackageLoc(Entity e) = |java+package:///| + replaceAll("<e>", ".", "/");
loc getCompilationUnitLoc(Entity e) = |java+compilationUnit:///| + ("src/main/java/" + replaceAll("<e>", ".", "/") + ".java");
loc getClassLoc(Entity e) = |java+class:///| + replaceAll("<e>", ".", "/");
loc getMethodLoc(Entity e) = |java+method:///| + (replaceAll(replaceAll("<e>", ".", "/"),"::","/") + "()");

bool entityIsPackage(Entity e, M3 m) = |java+package:///| + replaceAll("<e>", ".", "/") in m.declarations.name;
bool entityIsClass(Entity e, M3 m) = |java+class:///| + replaceAll("<e>", ".", "/") in m.declarations.name;
bool entityIsMethod(Entity e) = contains("<e>", "::");

list[str] getFileImports(loc file) {
	list[str] imports = [];
	list[str] lines = readFileLines(file);
	for (line <- lines) {
		str l = trim(line);
		if (line[0..6] == "import") imports += l;
	}
	return imports; 
}

list[str] getPackageImports(loc p, M3 m) {
	list[str] imports = [];
	for (cu <- m.containment[p]) {
		imports += getFileImports(cu);
	}
	return imports;
}

// Depends
Message mustDepend(Entity e1, Entity e2, M3 m3) {
	// e1 must depend on e2
	loc e1loc;
	list[str] imports;
	if (entityIsPackage(e1, m3)) {
		e1loc = getPackageLoc(e1);
		imports = getPackageImports(e1loc, m3); 	
	} else {
		e1loc = getCompilationUnitLoc(e1);
		imports = getFileImports(e1loc); 	
	}
	
	if (size([imp | imp <- imports, contains(imp, "<e2>")]) == 0) {
		return error("<e1> does not depend on <e2>, but it must", e1loc);
	}
	
	return info("<e1> does depend on <e2>", e1loc);	
}

Message cannotDepend(Entity e1, Entity e2, M3 m3) {
	// e1 cannot depend on e2
	loc e1loc;
	list[str] imports;
	if (entityIsPackage(e1, m3)) {
		e1loc = getPackageLoc(e1);
		imports = getPackageImports(e1loc, m3); 	
	} else {
		e1loc = getCompilationUnitLoc(e1);
		imports = getFileImports(e1loc); 	
	}

	if (size([imp | imp <- imports, contains(imp, "<e2>")]) != 0) {
		return error("<e1> depends on <e2>, but it cannot", e1loc);
	}
	
	return info("<e1> does not depend on <e2>", e1loc);
}

// Invokes
Message mustInvoke(Entity e1, Entity e2, M3 m3) {
	loc e1loc = getMethodLoc(e1);
	loc e2loc = getMethodLoc(e2);
	if (e2loc notin m3.methodInvocation[e1loc]) {
		return error("<e1> does not invoke <e2>, but it must", e1loc);
	}
	return info("<e1> does indeed invoke <e2>", e1loc);
}

Message cannotInvoke(Entity e1, Entity e2, M3 m3) {
	loc e1loc = getMethodLoc(e1);
	loc e2loc = getMethodLoc(e2);
	if (e2loc in m3.methodInvocation[e1loc]) {
		return error("<e1> does invoke <e2>, but it cannot", e1loc);
	}
	return info("<e1> does indeed invoke <e2>", e1loc);
}

// Inherits
Message mustInherit(Entity e1, Entity e2, M3 m3) {
	// e1 must inherit e2
	loc e1loc = getClassLoc(e1);
	loc e2loc = getClassLoc(e2);
	if (e2loc notin m3.extends[e1loc]) {
		return error("<e1> does not inherit <e2>, but it must", e1loc);
	}
	return info("<e1> does indeed inherit <e2>", e1loc);
}

Message cannotInherit(Entity e1, Entity e2, M3 m3) {
	// e1 must inherit e2
	loc e1loc = getClassLoc(e1);
	loc e2loc = getClassLoc(e2);
	if (e2loc in m3.extends[e1loc]) {
		return error("<e1> does inherit <e2>, but it cannot", e1loc);
	}
	return info("<e1> does indeed not inherit <e2>", e1loc);
}

Message canOnlyInherit(Entity e1, Entity e2, M3 m3) {
	// e1 must inherit e2
	loc e1loc = getClassLoc(e1);
	loc e2loc = getClassLoc(e2);
	if (size(m3.extends[e1loc]) == 0 || (size(m3.extends[e1loc]) == 1 && e2loc in m3.extends[e1loc])) {
		return info("<e1> does indeed only inherit <e2>", e1loc);
	}
	return error("<e1> can only inherit <e2>, but it doesnt", e1loc);
}

M3 jpacmanM3() = createM3FromEclipseProject(|project://jpacman/src|);
set[Message] main() = eval(parse(#start[Dicto], |project://sqat-analysis/src/sqat/series2/rules.dicto|) , jpacmanM3());
set[Message] eval(start[Dicto] dicto, M3 m3) = eval(dicto.top, m3);
set[Message] eval((Dicto)`<Rule* rules>`, M3 m3) = ( {} | it + eval(r, m3) | r <- rules );
  
set[Message] eval(Rule rule, M3 m3) {
	set[Message] msgs = {};
  
	switch (rule) {
		case (Rule)`<Entity e1> must depend <Entity e2>`: msgs += mustDepend(e1, e2, m3);
		case (Rule)`<Entity e1> cannot depend <Entity e2>`: msgs += cannotDepend(e1, e2, m3);
		case (Rule)`<Entity e1> must invoke <Entity e2>`: msgs += mustInvoke(e1, e2, m3);
		case (Rule)`<Entity e1> cannot invoke <Entity e2>`: msgs += cannotInvoke(e1, e2, m3);
		case (Rule)`<Entity e1> must inherit <Entity e2>`: msgs += mustInherit(e1, e2, m3);
		case (Rule)`<Entity e1> cannot inherit <Entity e2>`: msgs += cannotInherit(e1, e2, m3);
		case (Rule)`<Entity e1> can only inherit <Entity e2>`: msgs += canOnlyInherit(e1, e2, m3);
	}
	return msgs;
}

