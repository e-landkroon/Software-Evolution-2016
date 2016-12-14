module Main

import IO;
import Prelude;
import List;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

import demo::lang::Exp::Concrete::WithLayout::Syntax;

void main(){
	loc project = |project://TestProject|;	
	//loc project = |project://smallsql0.21_src|;	
	//loc project = |project://hsqldb-2.3.1|;
	
	M3 model = createM3FromEclipseProject(project);
	println("loaded");
	
	list[node] subtrees = [];
	for (f <- files(model)){
		subtrees += astToSubtrees(normTree(createAstFromFile(f, false)));
	}

	println("loaded2");
	
	map[node, list[loc]] duplicates = getDuplicates(subtrees);
	
	println("done");
	
	writeToFile(duplicates);
}

test bool subtreeLenTest(Declaration ast) {
	list[node] subs = astToSubtrees(ast);
	return (subs == [] || (min([ getWeight(x) | x <- subs ]) > 5));
} 

list[node] astToSubtrees(Declaration ast){
	list[node] subtrees = [];
	visit(ast){
		case node x: {
			if("src" in getAnnotations(x)){
				int weight = getWeight(x);  
				if (weight > 5) {
					subtrees += x;
				}
			}
		}
	}
	return subtrees;
}

//Length of regular traversal should equal the length of bottom-up traversal
// (i.e. test of rascal fundamentals).
test bool weightTest1(node a) {
	int count1 = 0;
	int count2 = getWeight(a);
	
	bottom-up visit(a) {
		case node x: count1 += 1;
	}
	return count1 == count2;
}   

int getWeight(node a) {
	int count = 0;
	visit(a) {
		case node x: count += 1;
	}
	return count;
}

test bool uniqueLocs(list[node] subtrees) {
	map[node, list[loc]] duplicates = getDuplicates(subtrees);
	int amtDups = 0;
	int unique = 0;
	return amtDups == unique; 
	//for (duplicate <- duplicates){ 	
	//	unique += max(distribution(dups[duplicate]));
	//	amtDups += 1;
	//}
	
	
}

map[node, list[loc]] getDuplicates(list[node] subtrees){
	
	println("start duplicates");
	map[node, list[loc]] duplicates = ();
	map[node, loc] processed = ();
	
	for (subtree <- subtrees){
		loc subtree_loc =  getLocFromNode(subtree);
		if (subtree in processed){
			if (subtree in duplicates)
				duplicates += (subtree : duplicates[subtree] + subtree_loc);
			else
				duplicates += (subtree : [subtree_loc, processed[subtree]]);
		}
		
		processed += (subtree : subtree_loc);
	}
	println("done dups");
	return duplicates;
}


Declaration normTree(Declaration ast){
	ast = visit(ast){
		case \variable(_, a, b) => \variable("var", a, b)
		case \variable(_, a) => \variable("var", a)
		case \enum(_, a, b, c) => \enum("var", a, b, c)
		case \enumConstant(_, a, b) => \enumConstant("var", a, b)
		case \enumConstant(_, a) => \enumConstant("var", a)
		case \class(_, a, b, c) => \class("var", a, b, c)
		case \method(a, _, b, c, d) => \method(a, "var", b, c, d)
		case \method(a, _, b, c) => \method(a, "var", b, c)
		case \constructor(_, a, b, c) => \constructor("var", a, b, c)

		case \vararg(a, _) => \vararg(a, "var")
		case \parameter(a, _, b) => \parameter(a, "var", b)  
		case \methodCall(a, _, b) => \methodCall(a, "var", b)
		case \methodCall(a, b, _, c) => \methodCall(a, b, "var", c)
		case \fieldAccess(a, _) => \fieldAccess(a, "var") 
		case \fieldAccess(a, b, _) => \fieldAccess(a, b, "var")
		case \simpleName(_) => \simpleName("var")
     	case \memberValuePair(_, a) => \memberValuePair("var", a)
     	case \label(_, a) => \label("var", a) 
	}
	return ast;
}

loc getLocFromNode(node subTree){
	if(Declaration x := subTree) return x@src;
	if(Statement x := subTree) return x@src;
	if(Expression x := subTree) return x@src;
	
}

void writeToFile(map[node, list[loc]] duplicates){
	loc location = |project://TestProject/blader.tmp|;
	str out = "";
	for(hit <- duplicates){
		for (dup <- duplicates[hit]){
			out += "<dup> ";
		}
		out += "\n";
	writeFile(location, out);
	}
}