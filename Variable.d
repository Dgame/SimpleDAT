module DAT.Variable;

import DAT.Lexer : Pair;

enum TypeType {
	None = 0,
	Array = 1,
	Pointer = 2
}

struct Var {
public:
	uint usage;
	
const:
	const(Pair)* typeInfo;
	
	TypeType extInfo;
	
	uint line;
	uint _scope;
	
	char[] name;
}