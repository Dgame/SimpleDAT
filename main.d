import std.stdio;
import std.file : dirEntries, SpanMode;
import std.array : split;
import std.string : strip, format;
import std.algorithm : endsWith;
import std.conv : text;
import std.getopt : getopt;

import DAT.Lexer;

immutable string Import = "import";

enum Protection : string {
	Public = "public",
	Private = "private",
	Protected = "protected",
	Package = "package"
}

struct NamedImport {
	const char[] name;
	uint[] useLines;
	
	this(const char[] name) {
		this.name = name;
	}
	
	@property
	uint use() const pure nothrow {
		return this.useLines.length;
	}
}

struct Imports {
public:
	const Protection prot;
	const uint line;
	const bool protBlock;
	
	NamedImport[] imports;
	
	this(Protection prot, uint line, bool protBlock) {
		this.prot = prot;
		this.line = line;
		this.protBlock = protBlock;
	}
}

void main(string[] args) {
	version(none) {
		version(none)
			const string filename = "D:/D/dmd2/src/phobos/std/csv.d";//"D:/D/dmd2/src/phobos/std/stdio.d";
		else
			const string filename = "../../test.d";
		
		warnForUnusedImports(filename, 2, true);
	} else 
	if (args.length > 1) {
		string files;
		string path;
		uint minUseCount;
		bool info;
		
		getopt(args, "f", &files, "d", &path, "use", &minUseCount, "info", &info);
		
		if (files.length != 0 && path.length != 0)
			assert(0, "Sorry, cannot work with --f and --d at the same time.");
		
		if (files.length != 0) {
			string[] filenames = files.split(",");
			writeln(files, " => ", filenames);
			string content;
			foreach (string filename; filenames) {
				if (filename.endsWith(".d")) {
					writeln("* ", filename);
					warnForUnusedImports(filename, minUseCount > 0 ? minUseCount : 1, info);
					writeln();
				}
			}
		} else if (path.length != 0) {
			string[] filenames;
			foreach (string name; dirEntries(path, SpanMode.depth)) {
				if (name.endsWith(".d")) {
					filenames ~= name.strip();
				}
			}
			
			string content;
			foreach (string filename; filenames) {
				writeln("* ", filename);
				warnForUnusedImports(filename, minUseCount > 0 ? minUseCount : 1, info);
				writeln();
			}
		}
	} else {
		writeln("--f \t scan multiple or one file(s)\n--d \t scan a whole path\n--use \t for the minimal use (default is 1)\n--info \t for used lines\n");
	}
} unittest {
	string[] output = findUnusedImports("D:/D/dmd2/src/phobos/std/stdio.d", 2, true);
	
	assert(output.length == 1);
	assert(output[0] == "\tNamed import std.c.stdio : FHND_WCHAR imported on line 35 is used 1 times. On lines: [2504]", "Output is: " ~ output[0]);
	
	output = findUnusedImports("../../test.d", 2, false);
	
	assert(output.length == 8);
	assert(output[0] == "\tNamed import std.string : format imported on line 6 is used 1 times.", "Output is: " ~ output[0]);
	assert(output[1] == "\tNamed import std.string : strip imported on line 6 is used 1 times.", "Output is: " ~ output[1]);
	assert(output[2] == "\tNamed import std.algorithm : startsWith imported on line 9 is never used.", "Output is: " ~ output[2]);
	assert(output[3] == "\tNamed import std.algorithm : endsWith imported on line 9 is never used.", "Output is: " ~ output[3]);
	assert(output[4] == "\tNamed import std.array : split imported on line 8 is never used.", "Output is: " ~ output[4]);
	assert(output[5] == "\tNamed import std.array : join imported on line 8 is never used.", "Output is: " ~ output[5]);
	assert(output[6] == "\tNamed import std.array : empty imported on line 8 is used 1 times.", "Output is: " ~ output[6]);
	assert(output[7] == "\tNamed import std.file : read imported on line 5 is never used.", "Output is: " ~ output[7]);
}

void warnForUnusedImports(string filename, uint minUse = 1, bool info = false) {
	const string[] warns = findUnusedImports(filename, minUse, info);
	foreach (string msg; warns) {
		writeln(msg);
	}
	
	if (warns.length == 0) {
		if (minUse == 1)
			writeln("\t", "No unused imports.");
		else
			writeln("\t", "No underused imports.");
	}
}

private Protection checkProtection(ref Lexer lex, bool* block) {
	Token* prev = &lex.token;
	
	while (prev.type != Tok.Semicolon && prev.type != Tok.RCurly && prev.type != Tok.None) {
		switch (prev.toChars()) {
			case Protection.Package:
			case Protection.Private:
			case Protection.Protected:
			case Protection.Public:
				if (prev.next.type == Tok.Colon || prev.next.type == Tok.LCurly)
					*block = true;
				
				return cast(Protection) prev.toChars();
			default: break;
		}
		
		prev = prev.prev;
	}
	
	return Protection.Private;
}

string[] findUnusedImports(string filename, uint minUse = 1, bool info = false) {
	Lexer lex = Lexer(filename);
	
	Imports[string] imps;
	Imports*[] lastImports;

	while (lex.token.type != Tok.Eof) {
		lex.nextToken();
		
		if (lex.token == Import) {
			bool protBlock = false;
			Protection prot = checkProtection(lex, &protBlock);
			
			if (lex.token.prev.type != Tok.RCurly && !protBlock
			    && lastImports.length != 0 && lastImports[$ - 1].protBlock)
			{
				prot = lastImports[$ - 1].prot;
				protBlock = true;
			}
			
			Imports curImp = Imports(prot, lex.loc.lineNum, protBlock);
			string impName;
			
			lex.nextToken();
			
			bool take = false;
			while (lex.token.type != Tok.Semicolon) {
				if (take && lex.token.isIdentifier()) {
					imps[impName].imports ~= NamedImport(lex.token.toChars());
				}
				
				if (lex.token.type == Tok.Colon) {
					take = true;
					
					imps[impName] = curImp;
					lastImports ~= &imps[impName];
				} else if (!take) {
					impName ~= lex.token.toChars();
				}
				
				lex.nextToken();
			}
		} else if (lex.token.isIdentifier()) {
			foreach (string impName, ref Imports imp; imps) {
				foreach (ref NamedImport nImp; imp.imports) {
					if (nImp.name == lex.token.toChars())
						nImp.useLines ~= lex.loc.lineNum;
				}
			}
		}
	}
	
	string[] output;
	foreach (string impName, ref Imports imp; imps) {
		ubyte useLess;
		foreach (ref const NamedImport nImp; imp.imports) {
			if (nImp.use < minUse) {
				if (nImp.use == 0) {
					output ~= format("\tNamed import %s : %s imported on line %d is never used.", impName, nImp.name, imp.line);
					
					if (info) {
						if (imp.prot == Protection.Public || imp.prot == Protection.Package)
							output[$ - 1] ~= "\n\t - But maybe '" ~ nImp.name ~ "' is used in other modules. [" ~ imp.prot ~ "]";
						else
							useLess++;
					}
				} else
					output ~= format("\tNamed import %s : %s imported on line %d is used %d times.", impName, nImp.name, imp.line, nImp.use);
				
				if (info && nImp.use != 0)
					output[$ - 1] ~= text(" On lines: ", nImp.useLines);
			}
		}
		
		if (useLess == imp.imports.length)
			output[$ - 1] ~= "\n\t - Therefore it is useless to import " ~ impName;
	}
	
	return output;
}