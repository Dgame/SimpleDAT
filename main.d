module main;

import std.stdio;
import std.file : read, dirEntries, SpanMode;
import std.array : split;
import std.string : splitLines, indexOf, strip, format;
import std.algorithm : startsWith, endsWith;
import std.ascii : isAlpha;
import std.conv : text;
import std.getopt : getopt;

immutable string Import = "import";

enum Protection : string {
	Public = "public",
	Private = "private",
	Protected =  "protected",
	Package = "package"
}

struct NamedImport {
	const string name;
	uint[] useLines;
	
	this(string name) {
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
	NamedImport[] imports;
}

void main(string[] args) {
	/*debug {
	 version(none)
	 const string content = cast(string) read("D:/D/dmd2/src/phobos/std/stdio.d");
	 else {
	 const string content = cast(string) read("../../test.d");
	 //			const string content = cast(string) read("../../main.d");
	 }
	 
	 warnForUnusedImports(content.splitLines(), 2, true);
	 } else */
	if (args.length > 1) {
		string files;
		string path;
		uint minUseCount;
		bool info;
		
		getopt(args, "f", &files, "d", &path, "use", &minUseCount, "info", &info);
		
		if (files.length != 0 && path.length != 0)
			assert(0, "Sorry, cannot work with --f and --d at the same time.");
		
		if (files.length != 0) {
			string[] filenames = files.split();
			string content;
			foreach (string filename; filenames) {
				if (filename.endsWith(".d")) {
					content = cast(string) read(filename.strip());
					warnForUnusedImports(content.splitLines(), minUseCount > 0 ? minUseCount : 1, info);
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
				if (filename.endsWith(".d")) {
					content = cast(string) read(filename);
					warnForUnusedImports(content.splitLines(), minUseCount > 0 ? minUseCount : 1, info);
				}
			}
		}
	} else {
		writeln("--f \t scan multiple or one file(s)\n--d \t scan a whole path\n--use \t for the minimal use (default is 1)\n--info \t for used lines\n");
	}
} unittest {
	static assert(Import == "import");
	
	string content = cast(string) read("D:/D/dmd2/src/phobos/std/stdio.d");
	string[] output = findUnusedImports(content.splitLines(), 2, true);
	
	assert(output.length == 1);
	assert(output[0] == "Named import std.c.stdio : FHND_WCHAR imported on line 35 is used 1 times. On lines: [2504]", "Output is: " ~ output[0]);
	
	content = cast(string) read("../../test.d");
	output = findUnusedImports(content.splitLines(), 2, false);
	
	assert(output.length == 6);
	assert(output[0] == "Named import std.string : format imported on line 5 is never used.", "Output is: " ~ output[0]);
	assert(output[1] == "Named import std.string : strip imported on line 5 is used 1 times.", "Output is: " ~ output[1]);
	assert(output[2] == "Named import std.array : split imported on line 6 is never used.", "Output is: " ~ output[2]);
	assert(output[3] == "Named import std.array : join imported on line 6 is never used.", "Output is: " ~ output[3]);
	assert(output[4] == "Named import std.array : empty imported on line 6 is used 1 times.", "Output is: " ~ output[4]);
	assert(output[5] == "Named import std.file : read imported on line 4 is never used.", "Output is: " ~ output[5]);
}

void warnForUnusedImports(string[] lines, uint minUse = 1, bool info = false) {
	foreach (string msg; findUnusedImports(lines, minUse, info)) {
		writeln(msg);
	}
}

private bool checkForComment(const string line, ref bool[2] comment) {
	/// Line comment
	if (line.startsWith("//"))
		return false;
	
	if (comment[0] && line.endsWith("*/"))
		comment[0] = false;
	
	if (comment[1] && line.endsWith("+/"))
		comment[1] = false;
	
	if (line.startsWith("/*"))
		comment[0] = true;
	
	if (line.startsWith("/+"))
		comment[1] = true;
	
	return true;
}

private Protection checkProtection(const string[] words, uint wnr) {
	if (wnr != 0) {
		switch (words[wnr - 1]) {
			case Protection.Package:
			case Protection.Private:
			case Protection.Protected:
			case Protection.Public:
				return cast(Protection) words[wnr - 1];
			case "{":
			case ":":
				return checkProtection(words, wnr - 1);
			default: 
				return Protection.Private;
		}
	}
	
	return Protection.Private;
}

string[] findUnusedImports(string[] lines, uint minUse = 1, bool info = false) {
	Imports[string] namedImports;
	
	bool[2] comment = false;
	
	foreach (uint nr, string line; lines) {
		line = line.strip();
		if (line.length == 0)
			continue;
		
		if (!checkForComment(line, comment))
			continue;
		
		if (comment[0] || comment[1])
			continue;
		
		string[] words = line.split();
		foreach (uint wnr, string word; words) {
			if (word.indexOf('"') != -1)
				break;
			
			if (word.length > 1) {
				if (word == Import) {
					Protection prot = checkProtection(words, wnr);
					
					if (line.indexOf(':') != -1) {
						string[2] splitter = line.split(":");
						string[] named = splitter[1].split(",");
						
						const string impName = splitter[0].split()[wnr + 1].strip();
						
						namedImports[impName] = Imports(prot, nr);
						foreach (name; named) {
							if (name.indexOf(';') != -1)
								name = name[0 .. $ - 1];
							
							namedImports[impName].imports ~= NamedImport(name.strip());
						}
					}
					
					break;
				}
			}
		}
	}
	
	string[] output;
	comment[] = false;
	
	foreach (string key, ref Imports imp; namedImports) {
		foreach (ref NamedImport nImp; imp.imports) {
			foreach (uint nr, string line; lines) {
				line = line.strip();
				if (line.length == 0)
					continue;
				
				if (!checkForComment(line, comment))
					continue;
				
				if (comment[0] || comment[1])
					continue;
				
				if (nr == imp.line)
					continue;
				
				/// search
				for (uint i = 0; i < line.length; ++i) {
					/// ignore strings
					if (line[i] == '"') {
						i++;
						while (i < line.length && line[i] != '"')
							i++;
						
						if (i >= line.length)
							break;
					}
					
					char[] word;
					while (isAlpha(line[i]) || line[i] == '_') {
						word ~= line[i];
						
						i++;
						if (i >= line.length)
							break;
					}
					
					if (word.length != 0 && word == nImp.name)
						nImp.useLines ~= nr + 1;
				}
			}
			
			if (nImp.use < minUse) {
				if (nImp.use == 0) {
					output ~= format("Named import %s : %s imported on line %d is never used.", key, nImp.name, imp.line + 1);
					
					if (info && (imp.prot == Protection.Public || imp.prot == Protection.Package))
						output[$ - 1] ~= "\n But maybe '" ~ nImp.name ~ "' is used in other modules. [" ~ imp.prot ~ "]";
				} else
					output ~= format("Named import %s : %s imported on line %d is used %d times.", key, nImp.name, imp.line + 1, nImp.use);
				
				if (info && nImp.use != 0)
					output[$ - 1] ~= text(" On lines: ", nImp.useLines);
			}
		}
	}
	
	return output;
}