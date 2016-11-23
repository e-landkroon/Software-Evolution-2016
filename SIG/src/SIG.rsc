module SIG

import IO;
import Prelude;
import List;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

public void main() {
	loc project = |project://smallsql0.21_src|;	
	model = createM3FromEclipseProject(project);
	myMethods = methods(model);
	println("loaded");
	//Is different from the sum of lines in all units.
	allLOC = getAllLinesCommentFree(model);
	volume = size(allLOC);
	tuple[int,int] unitStats = getUnitStats(model);
	int duplicates = getDuplicates(allLOC);
	println("
vol:<volume>
complexity:<unitStats[0]>
dups:<duplicates>
total unit size: <unitStats[1]>
	");
	//
	//lrel[num, num] unitInfo = [analyzeUnit(inf, model) | inf <- myMethods];
	//rPercent = convertPercentage(unitInfo, totalLOC);
	//println(complexity(rPercent));
	//println(size(myMethods));
	//printStats(1,complexity(rPercent),3,4);
}

tuple[int,int] getUnitStats(M3 model) {
	lrel[num, num] unitInfo = [analyzeUnit(inf, model) | inf <- methods(model)];
	int totalUnitLOC = (0 | it + unitloc | <risk,unitloc> <- unitInfo);
	return <complexity(convertPercentage(unitInfo, totalUnitLOC)), totalUnitLOC>;
}

list[num] convertPercentage(lrel[num,num] units, int totalLOC) {
	return [(rBin / totalLOC) * 100 | rBin <- riskBins(units)];
}

//Returns the proper complexity risk based on the percentage and gradation of complexity of the methods.
int complexity(list[num] bins) {
	println("
	Complexity Report:
	<bins[0]> of the code is of very low complexity.
	<bins[1]> of the code is of low complexity.
	<bins[2]> of the code is of moderate complexity.
	<bins[3]> of the code is of high complexity.
	");
	if (bins[3] >= 5.0 || bins[2] >= 15.0 || bins[1] >= 50.0) return 4;
	if (bins[2] >= 10.0 || bins[1] >= 40.0) return 3;
	if (bins[2] >= 5.0 || bins[1] >= 30.0) return 2;
	if (bins[1] >= 25.0) return 1;
	return 0;
}

//Construct bins with the total lines of code per risk level
list[num] riskBins(lrel[num,num] riskArr) {
	bins = [
		(0 | it + y | <x,y> <- riskArr, x == 0),
		(0 | it + y | <x,y> <- riskArr, x == 1),
		(0 | it + y | <x,y> <- riskArr, x == 2),
		(0 | it + y | <x,y> <- riskArr, x == 3)
	];
	return bins;
}

//Analyses a unit of code and returns the risk number
// (numbers were based on the paper of Heitlager).
tuple[num,num] analyzeUnit(loc unitLoc, M3 model) {
	ast = getMethodASTEclipse(unitLoc, model = model);
	count = 0;
	num risk = 0;
	int lines = countLines(readFileLines(unitLoc));
	
	visit(ast) {
		case m: \method(_,_,_,_, Statement impl): count += countcomplex(impl);
		case c: \constructor(_,_,_, Statement impl): count += countcomplex(impl);
	}
	
	if (count > 10 && count < 21) risk = 1;
	if (count > 20 && count < 51) risk = 2;
	if (count > 50) risk = 3;
 
	return <risk, lines>;
}

//Counts the complex statements.
int countcomplex(Statement impl){
	count = 0;
	
	visit (impl) {
		case \case(_): count += 1;
		case \catch(_,_): count += 1;
		case \conditional(_,_,_): count += 1;
		case \do(_,_): count += 1;
		case \for(_,_,_): count += 1;
		case \for(_,_,_,_) : count += 1;
		case \foreach(_,_,_): count += 1;
		case \if(_,_): count += 1;
		case \if(_,_,_): count += 1;
		case \infix(_,"||", _): count += 1;
		case \infix(_, "&&", _): count += 1;
		case \while(_,_): count += 1;
	}
	
	return count;
}

int countLines(list[str] lines){
	return size(removeComments(lines));
}

int getVolume(){
	return size(getAllLinesCommentFree());
}

int getDuplicates(){
list[str] lines = getAllLinesCommentFree();
	return duplicates(lines);
}

real getDuplicatePercentage(){
	list[str] lines = getAllLinesCommentFree();
	return duplicates(lines) * 100.0 / toReal(size(lines));
}

map[loc,int] getUnitSizes(){
	return (m : countLines(readFileLines(m)) | m <- myMethods);
}

list[str] getAllLinesCommentFree(M3 myModel){
	list[str] lines = [];
	
	for	(f <- files(myModel)){
		lines += removeComments(readFileLines(f));
	}
	return lines;	
}


// Function for removing the comments from the lines
list[str] removeComments(list[str] lines){
	bool multiLineComment = false;
	list[str] newLines = [];
	
	for (l <- lines){
		// Removes white spaces to make matchin easier
		line = trim(l);
		
		switch(line){
			
			// Skips empty line		
			case "": {continue;}
			
			// Skips single line comment
			case /\/\/.*/ : {continue;}
			
			// Skips multi line comment (single)
			case /\/\*.*\*\//: {continue;}
			
			// Skips multi line comment begin
			case /\/\*.*/: {
				multiLineComment = true;
				continue;
			}
			
			// Skips multi line comment end
			case /.*\*\//: {
				multiLineComment = false;
				continue;
			}
				
			default: {
				// Count lines if not in multi line comment block
				if (multiLineComment){
					continue;
				}
				newLines += line;
			}		
		}
	}
	return newLines;
}


// Function to get the ammount of duplicate lines
int getDuplicates(list[str] lines)
{
	map[str, int] processedLines = ();
	int duplicates = 0;
	bool prev = false;
	
	for (i <- [0 .. size(lines) - 6]){
		// Create a string of 6 combined lines
		str line = lines[i] + lines[i + 1] + lines[i + 2] + lines[i + 3] + lines[i + 4] + lines[i + 5];
		
		// Checks if the combined line is in the processed lines map
		if(line in processedLines){
			// Add 6 if the previous line wasn't in the processed lines, 1 if the previous line was in the combined lines
			if(prev)
				duplicates += 1;
			else{
				prev = true;
				duplicates += 6;
			}
		}else{
			// If the line isn't in the processed lines, than add it
			prev = false;
			processedLines += (line : i);
		}
	}
	return duplicates;
}



void printStats(int volume, int complexity, int duplicate, int unitSize){
	
	int analysability = (volume + duplicate + unitSize) / 3;
	int changeability = (complexity + duplicate) / 2;
	int stability = 2;
	int testability = (complexity + unitSize) / 2;
	
	println("
		+---------------------+
		|Analisability  |  <analysability>  |
		+---------------------+
		|Changeability  |  <changeability>  |
		+---------------------+
		|Stability      |  <stability>  |
		+---------------------+
		|Testability    |  <testability>  |
		+-------------+-------+");
}


