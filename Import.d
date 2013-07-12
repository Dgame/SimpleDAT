module DAT.Import;

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