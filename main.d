import std.stdio;
import std.file : dirEntries, SpanMode, remove;
import std.array : split, insertInPlace, join;
import std.string : strip, format, indexOf, toLower;
import std.algorithm : endsWith, countUntil;
import std.conv : text, to;
import std.getopt : getopt;
import std.process : executeShell;

import DAT.Lexer;
import DAT.Import;
import DAT.Stack;
import DAT.Variable;

enum Flags {
	None = 0,
	Info = 1,
	ShowAll = 2
}

void main(string[] args) {
	debug {
		version(all)
			const string filename = "D:/D/dmd2/src/phobos/std/stdio.d"; /// "D:/D/dmd2/src/phobos/std/csv.d";
		else
			const string filename = "../../../test.d"; /// "C:/Users/Besitzer/Documents/GitHub/Dgame/Audio/Sound.d";
		
		checkModifier(filename);
		warnForUnusedImports(filename, Flags.Info | Flags.ShowAll, 2);
		warnForUnusedVariables(filename, 2);
	} else if (args.length > 1) {
		string files;
		string path;
		uint iMinUseCount, vMinUseCount;
		bool info, showAll, varUse, modCheck;
		
		getopt(args,
		       "f", &files, "d", &path, "iUse",
		       &iMinUseCount, "info", &info,
		       "showAll", &showAll,
		       "vUse", &vMinUseCount, "varUse", &varUse,
		       "modCheck", &modCheck);
		
		Flags flags;
		if (info)
			flags |= Flags.Info;
		if (showAll)
			flags |= Flags.ShowAll;
		
		if (files.length != 0 && path.length != 0)
			assert(0, "Sorry, cannot work with --f and --d at the same time.");
		
		if (files.length != 0) {
			string[] filenames = files.split(",");
			//			writeln(files, " => ", filenames);
			uint total = 0, ocFiles = 0;
			
			string content;
			foreach (string filename; filenames) {
				if (filename.endsWith(".d")) {
					writeln("* ", filename);
					uint ocs = warnForUnusedImports(filename, flags, iMinUseCount > 0 ? iMinUseCount : 1);
					writeln();
					
					if (ocs) {
						total += ocs;
						ocFiles++;
					}
				}
			}
			
			writeln("----\n", total, " occurrences in ", ocFiles, " / ", filenames.length, " files.");
			
			if (varUse) {
				foreach (string filename; filenames) {
					if (filename.endsWith(".d")) {
						writeln("* ", filename);
						warnForUnusedVariables(filename, vMinUseCount > 0 ? vMinUseCount : 1);
					}
				}
			}
			
			if (modCheck) {
				foreach (string filename; filenames) {
					if (filename.endsWith(".d")) {
						writeln("* ", filename);
						checkModifier(filename);
					}
				}
			}
			
		} else if (path.length != 0) {
			string[] filenames;
			foreach (string name; dirEntries(path, SpanMode.depth)) {
				if (name.endsWith(".d")) {
					filenames ~= name.strip();
				}
			}
			
			uint total = 0, ocFiles = 0;
			
			string content;
			foreach (string filename; filenames) {
				writeln("* ", filename);
				uint ocs = warnForUnusedImports(filename, flags, iMinUseCount > 0 ? iMinUseCount : 1);
				writeln();
				
				if (ocs) {
					total += ocs;
					ocFiles++;
				}
			}
			
			writeln("----\n", total, " occurrences in ", ocFiles, " / ", filenames.length, " files.");
			writeln("----\n");
			
			if (varUse) {
				foreach (string filename; filenames) {
					writeln("* ", filename);
					warnForUnusedVariables(filename, vMinUseCount > 0 ? vMinUseCount : 1);
				}
			}
			
			
			if (modCheck) {
				foreach (string filename; filenames) {
					writeln("* ", filename);
					checkModifier(filename);
				}
			}
		}
	} else {
		writeln("--f \t\t scan multiple or one file(s)\n--d \t\t scan a whole path\n--iUse \t\t for the minimal import use (default is 1)\n--info \t\t for used lines\n--showAll \t show public / package imports\n--varUse \t detect unused / underused built-in variables (alpha state) \n--vUse \t\t for the minimal variable use (default is 1) \n--modCheck \t Checks your functions if they could have any more modifier.");
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

uint warnForUnusedImports(string filename, Flags flags, uint minUse = 1) {
	const string[] warns = findUnusedImports(filename, flags, minUse);
	foreach (string msg; warns) {
		writeln(msg);
	}
	
	if (warns.length == 0) {
		if (minUse == 1)
			writeln("\t", "No unused imports.");
		else
			writeln("\t", "No underused imports.");
	}
	
	return warns.length;
}

void checkModifier(string filename) {
	Lexer lex = Lexer(filename);
	
	while (lex.token.type != Tok.Eof) {
		Mod mod = lex.parseModifier();
		
		if (lex.token.isIdentifier() && lex.peekAhead().type == Tok.LParen) {
			Token old = lex.token;
			
			lex.nextToken();
			lex.skipParents();
			
			Mod mod2 = lex.parseModifier();
			
			if (lex.token.type == Tok.LCurly) {
				writeln("----");
				debug writefln(" - Examine function %s ...", old.toChars());
				
				bool result = false;
				foreach (Mod mod, int res;
				         TryMods(lex.loc.lineNum, lex._content.splitLines(), mod, mod2))
				{
					if (res == 0) {
						result = true;
						
						writefln(" - Function %s could have modifier %s.", old.toChars(), to!string(mod).toLower());
					}
				}
				
				if (!result) {
					writefln(" - No need for further modifiers for function %s.", old.toChars());
				}
				
				writeln("----\n");
			}
		}
		
		lex.nextToken();
	}
}

private int[Mod] TryMods(uint lineNr, string[] lines, Mod before, Mod behind) {
	Mod comb = before ^ behind;
	
	string need;
	int[Mod] result;
	
	while (true) {
		Mod curMod;
		
		if (!(comb & Mod.Pure)) {
			need = " pure";
			
			curMod = Mod.Pure;
		} else if (!(comb & Mod.Const)) {
			need = " const";
			
			curMod = Mod.Const;
		} else if (!(comb & Mod.Nothrow)) {
			need = " nothrow";
			
			curMod = Mod.Nothrow;
		} else if (!(comb & Mod.Immutable)) {
			need = " immutable";
			
			curMod = Mod.Immutable;
		}
		
		if (curMod == Mod.None)
			break;
		
		debug writeln("Try mod:", need);
		
		comb |= curMod;
		
		if (uint pos = lines[lineNr - 1].indexOf('{'))
			lines[lineNr - 1].insertInPlace(pos - 1, need);
		
		File f = File("__test.d", "w+");
		f.write(lines.join("\n"));
		f.close();
		
		scope(exit) .remove("__test.d");
		
		result[curMod] = .executeShell("dmd __test.d").status;
	}
	
	return result;
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
		
		prev = prev.previous;
	}
	
	return Protection.Private;
}

string[] findUnusedImports(string filename, Flags flags, uint minUse = 1) {
	Lexer lex = Lexer(filename);
	
	Imports[string] imps;
	Imports*[] lastImports;
	
	uint[][string] wrongUsed;
	
	while (lex.token.type != Tok.Eof) {
		lex.nextToken();
		
		if (lex.token.isKeyword() && lex.token.pair.id == Keyword.import_) {
			bool protBlock = false;
			Protection prot = checkProtection(lex, &protBlock);
			
			if (lex.token.previous.type != Tok.RCurly && !protBlock
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
					if (nImp.name == lex.token.toChars()) {
						if (lex.token.previous.type == Tok.Dot) {
							Token* prev = lex.token.previous.previous;
							
							char[] id;
							while (prev.type == Tok.Dot || prev.isIdentifier()
							       || (prev.isType() && prev.pair.id == Type.string_))
							{
								id = prev.toChars() ~ id;
								prev = prev.previous;
							}
							
							if (impName == id) {
								wrongUsed[impName] ~= lex.loc.lineNum;
								
								continue;
							}
						}
						
						nImp.useLines ~= lex.loc.lineNum;
					}
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
					if ((imp.prot != Protection.Public && imp.prot != Protection.Package) || flags & Flags.ShowAll) {
						string msg = "never";
						if (impName in wrongUsed)
							msg = "wrong";
						
						output ~= format("\tNamed import %s : %s imported on line %d is %s used.",
						                 impName, nImp.name, imp.line, msg);
						
						if (impName in wrongUsed)
							output[$ - 1] ~= text(" On lines: ", wrongUsed[impName]);
						
						//if (flags & Flags.Info) {
						if (imp.prot == Protection.Public || imp.prot == Protection.Package)
							output[$ - 1] ~= "\n\t - But maybe '" ~ nImp.name ~ "' is used in other modules. [" ~ imp.prot ~ "]";
						else
							useLess++;
						//}
					}
				} else
					output ~= format("\tNamed import %s : %s imported on line %d is used %d times.", impName, nImp.name, imp.line, nImp.use);
				
				if (flags & Flags.Info && nImp.use != 0)
					output[$ - 1] ~= text(" On lines: ", nImp.useLines);
			}
		}
		
		if (useLess == imp.imports.length)
			output[$ - 1] ~= "\n\t - Therefore it is useless to import " ~ impName;
	}
	
	return output;
}

uint warnForUnusedVariables(string filename, uint minUse = 1) {
	const string[] warns = findUnusedVariables(filename, minUse);
	foreach (string msg; warns) {
		writeln(msg);
	}
	
	if (warns.length == 0) {
		if (minUse == 1)
			writeln("\t", "No unused variables.");
		else
			writeln("\t", "No underused variables.");
	}
	
	return warns.length;
}

string[] findUnusedVariables(string filename, uint minUse = 1) {
	Lexer lex = Lexer(filename);
	
	uint curScope = 0;
	
	Stack!uint stack;
	stack.push(curScope);
	
	Var[char[]][uint] vars;
	
	while (lex.token.type != Tok.Eof) {
		//		writeln(lex.loc.lineNum);
		lex.nextToken();
		
		
		if (lex.token.isType()) {
			auto typeInfo = lex.token.pair;
			TypeType extTypeInfo;
			
		L1:
			if (lex.peekAhead().isIdentifier()
			    && (lex.peekAhead2().type == Tok.Assign || lex.peekAhead2().type == Tok.Semicolon))
			{
				version(none) {
					writeln(" Should ID: ", lex.peekAhead().type);
					lex.nextToken();
					writeln(lex.token.toChars(), "::", typeInfo.value, " -> ", lex.token.type);
				} else {
					lex.nextToken();
				}
				
				const char[] name = lex.token.toChars();
				version(none) writeln("Var: ", name);
				
				uint usage = 0;
				if (lex.peekAhead().type == Tok.Assign)
					usage = 1;
				
				vars[stack.top()][name] = Var(usage, typeInfo, extTypeInfo, lex.loc.lineNum, 
				                              stack.top(), name);
			} else if (lex.peekAhead().isIdentifier()) {
				if (lex.peekAhead().type == Tok.Star)
					extTypeInfo = TypeType.Pointer;
				else if (lex.peekAhead().type == Tok.LBracket)
					extTypeInfo = TypeType.Array;
				
				if (extTypeInfo == TypeType.None)
					goto L2;
				
				while (!lex.peekAhead().isIdentifier()) {
					lex.nextToken();
				}
				
				goto L1;
			}
		} else if (lex.token.isIdentifier()) {
			const char[] name = lex.token.toChars();
			
			int lastScope = -1;
			for (int i = stack.top(); i >= 0; i--) {
				if (i in vars && name in vars[i] && lastScope == -1) {
					//writeln(vars[i][name], "::", i, "::", stack.top(), lastScope);
					vars[i][name].usage++;
					
					lastScope = vars[i][name]._scope;
				}
			}
		}
		
	L2:
		
		if (lex.token.type == Tok.LCurly) {
			curScope++;
			//			writeln("neuer scope [", curScope, "] @ ", lex.loc.lineNum);
			
			stack.push(curScope);
		} else if (lex.token.type == Tok.RCurly) {
			//			writeln("raus aus [", curScope, "] @ ", lex.loc.lineNum);
			
			stack.pop();
		}
	}
	
	//	writeln(vars);
	
	string[] output;
	
	foreach (_scope, varMap; vars) {
		foreach (ref Var var; varMap) {
			if (var.usage < minUse) {
				string kind;
				final switch (var.extInfo) {
					case TypeType.Array:
						kind = "array";
						break;
					case TypeType.Pointer:
						kind = "pointer";
						break;
					case TypeType.None:
						kind = "variable";
						break;
				}
				
				output ~= format("%s %s of type %s (declared on line %d) is %s.",
				                 kind, var.name, var.typeInfo.value, var.line,
				                 (minUse == 1 ? "unused" : text("used ", var.usage, " times")));
			}
		}
	}
	
	return output;
}