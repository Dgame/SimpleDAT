module DAT.Lexer;

import std.stdio;
import std.file : exists, read;
import std.c.string : memcpy;

enum Tok {
	None,
	Assign, /// =
	At, /// @
	BitAnd, /// &
	BitAndAssign, /// &=
	BitOr, /// |
	BitOrAssign, /// |=
	CatAssign, /// ~=
	Colon, /// :
	Comma, /// ,
	Decrement, /// --
	Div, /// /
	DivAssign, /// /=
	Dollar, /// $
	Dot, /// .
	Equals, /// ==
	GoesTo, /// =>
	Greater, /// >
	GreaterEqual, /// >=
	Hash, /// #
	Increment, /// ++
	LCurly, /// {
	LBracket, /// [
	Less, /// <
	LessEqual, /// <=
	LessEqualGreater, /// <>=
	LessOrGreater, /// <>
	LogicAnd, /// &&
	LogicOr, /// ||
	LParen, /// $(LPAREN)
	Minus, /// -
	MinusAssign, /// -=
	Mod, /// %
	ModAssign, /// %=
	MulAssign, /// *=
	Not, /// !
	NotEquals, /// !=
	NotGreater, /// !>
	NotGreaterEqual, /// !>=
	NotLess, /// !<
	NotLessEqual, /// !<=
	NotLessEqualGreater, /// !<>
	Plus, /// +
	PlusAssign, /// +=
	Pow, /// ^^
	PowAssign, /// ^^=
	RCurly, /// }
	RBracket, /// ]
	RParen, /// $(RPAREN)
	Semicolon, /// ;
	ShiftLeft, /// <<
	ShiftLeftAssign, /// <<=
	ShiftRight, /// >>
	ShiftRightAssign, /// >>=
	Slice, /// ..
	Star, /// *
	Ternary, /// ?
	Tilde, /// ~
	Unordered, /// !<>=
	UnsignedShiftRight, /// >>>
	UnsignedShiftRightAssign, /// >>>=
	VarArg, /// ...
	Xor, /// ^
	XorAssign, /// ^=
	
	Backslash, /// \
	
	Eof, // End of file
	
	// Comment, /// $(D_COMMENT /** comment */) or $(D_COMMENT // comment) or $(D_COMMENT ///comment)
	Identifier,
	Keyword,
	Type,
	Property,
	
	// Whitespace, /// whitespace
	// Newline, // Newlines
	
	DoubleLiteral, /// 123.456
	FloatLiteral, /// 123.456f or 0x123_45p-3
	// IdoubleLiteral, /// 123.456i
	// IfloatLiteral, /// 123.456fi
	IntLiteral, /// 123 or 0b1101010101
	LongLiteral, /// 123L
	RealLiteral, /// 123.456L
	// IrealLiteral, /// 123.456Li
	UintLiteral, /// 123u
	UlongLiteral, /// 123uL
	CharacterLiteral, /// 'a'
	DCharacterLiteral, /// w'a'
	WCharacterLiteral, /// d'a'
	DStringLiteral, /// $(D_STRING 32-bit character stringd)
	StringLiteral, /// $(D_STRING an 8-bit string)
	WStringLiteral, /// $(D_STRING 16-bit character stringw)";
	RegexStringLiteral, /// all string literals which starts with 'r'
	MultiLineString, /// Starts with `
	HexLiteral, /// 0xFFFFFF
	BinaryLiteral, /// 0b010011
}

private static immutable string[66] tokenValues = ["Invalid Tok",
                                                   "=",
                                                   "@",
                                                   "&",
                                                   "&=",
                                                   "|",
                                                   "|=",
                                                   "~=",
                                                   ":",
                                                   ",",
                                                   "--",
                                                   "/",
                                                   "/=",
                                                   "$",
                                                   ".",
                                                   "==",
                                                   "=>",
                                                   ">",
                                                   ">=",
                                                   "#",
                                                   "++",
                                                   "{",
                                                   "[",
                                                   "<",
                                                   "<=",
                                                   "<>=",
                                                   "<>",
                                                   "&&",
                                                   "||",
                                                   "(",
                                                   "-",
                                                   "-=",
                                                   "%",
                                                   "%=",
                                                   "*=",
                                                   "!",
                                                   "!=",
                                                   "!>",
                                                   "!>=",
                                                   "!<",
                                                   "!<=",
                                                   "!<>",
                                                   "+",
                                                   "+=",
                                                   "^^",
                                                   "^^=",
                                                   "}",
                                                   "]",
                                                   ")",
                                                   ";",
                                                   "<<",
                                                   "<<=",
                                                   ">>",
                                                   ">>=",
                                                   "..",
                                                   "*",
                                                   "?",
                                                   "~",
                                                   "!<>=",
                                                   ">>>",
                                                   ">>>=",
                                                   "...",
                                                   "^",
                                                   "^=",
                                                   "\\",
                                                   "Eof"];

private static immutable string[94] Keywords = ["abstract", "alias", "align", "asm", "assert", "auto",
                                                "body", "break",
                                                "case", "cast", "catch", "cdouble", "class", "const", "continue",
                                                "debug", "default", "delegate", "delete", "deprecated", "do",
                                                "else", "enum", "export", "extern",
                                                "false", "final", "finally", "for", "foreach", "foreach_reverse", "function",
                                                "goto",
                                                "if", "immutable", "import", "in", "inout", "interface", "invariant", "is",
                                                "lazy",
                                                "macro", "mixin", "module", "new", "nothrow", "null",
                                                "out", "override",
                                                "package", "pragma", "private", "protected", "public", "pure",
                                                "ref", "return",
                                                "scope", "shared", "static", "struct", "super", "switch", "synchronized",
                                                "template", "this", "throw", "true", "try", "typedef", "typeid", "typeof",
                                                "union", "unittest",
                                                "version", "volatile",
                                                "while", "with",
                                                "__FILE__", "__MODULE__", "__LINE__", "__FUNCTION__", "__PRETTY_FUNCTION__",
                                                "__gshared", "__traits", "__vector", "__parameters", "__DATE__", "__EOF__",
                                                "__TIME__", "__TIMESTAMP__", "__VENDOR__", "__VERSION__"];

private static immutable string[29] Types = ["void",
                                             "bool",
                                             "byte", "ubyte",
                                             "short", "ushort",
                                             "int", "uint",
                                             "long", "ulong",
                                             "cent", "ucent",
                                             "float", "double",
                                             "real",
                                             "ifloat", "idouble",
                                             "ireal",
                                             "cfloat", "cdouble",
                                             "creal",
                                             "char", "wchar", "dchar",
                                             "string", "wstring", "dstring",
                                             "size_t", "ptrdiff_t"];

private bool contains(const uint N)(ref immutable string[N] array, const char[] value) {
	foreach (ref const string item; array) {
		if (item == value)
			return true;
	}
	
	return false;
}

private string getTokenValue(Tok tok) pure nothrow {
	return tok < tokenValues.length ? tokenValues[tok] : "Undefinied Tok";
}

struct Token {
public:
	Token* next;
	Token* prev;
	
	char* ptr;		 // pointer to first character of this token within buffer
	uint len;
	
	Tok type;
	
	const(char)[] toChars() const pure nothrow {
		return this.ptr ? this.ptr[0 .. this.len] : getTokenValue(this.type);
	}
	
	bool isIdentifier() const pure nothrow {
		return this.type == Tok.Identifier;
	}
	
	bool isType() const pure nothrow {
		return this.type == Tok.Type;
	}
	
	bool isKeyword() const pure nothrow {
		return this.type == Tok.Keyword;
	}
	
	bool opEquals(ref const Token tok) const pure nothrow {
		return this.type == tok.type && this.toChars() == tok.toChars();
	}
	
	bool opEquals(Tok tok) const pure nothrow {
		return this.type == tok;
	}
	
	bool opEquals(const char[] value) const pure nothrow {
		return this.toChars() == value;
	}
}

struct Loc {
	const string filename;
	size_t lineNum;
	
	this(string filename, size_t line) {
		this.lineNum  = line;
		this.filename = filename;
	}
	
	this(string filename) {
		this(filename, 1);
	}
	
	bool opEquals(ref const Loc loc) const pure nothrow {
		return this.lineNum == loc.lineNum && this.filename == loc.filename;
	}
}

void error(Args...)(string msg, ref const Loc loc, Args args) {
	static if (args.length != 0) {
		msg = std.string.format(msg, args);
	}
	
	throw new Exception(msg, loc.filename, loc.lineNum);
}

enum LS = 0x2028;	   // UTF line separator
enum PS = 0x2029;	   // UTF paragraph separator

struct Lexer {
	Loc loc; // for error messages
	char* _p; // current character
	Token token;
	
	enum Comment {
		None,
		Line,
		Plus,
		Star
	}
	
	Comment ctype; // current comment style
	
	@disable
	this();
	
	@disable
	this(this);
	
	this(string filename) {
		if (!exists(filename))
			throw new Exception("Datei " ~ filename ~ " existiert nicht.");
		
		this.loc.filename = filename;
		this.loc.lineNum  = 1;
		
		_p = &(cast(char[]) read(filename))[0];
		
		if (_p[0] == '#' && _p[1] =='!') {
			_p += 2;
			
			while (true) {  
				switch (*_p) {
					case '\n':
						_p++;
						break;
					case '\r':
						_p++;
						if (*_p == '\n')
							_p++;
						break;
					case 0:
					case 0x1A: break;
					default:
						if (*_p & 0x80) {
							const dchar u = *_p;
							if (u == PS || u == LS)
								break;
						}
						_p++;
						continue;
				}
				break;
			}
			
			this.loc.lineNum = 2;
		}
	}
	
	Token* nextToken() {
		if (this.token.next)
			return this.token.next;
		
		this.token.next = new Token();
		
		Token* prev = new Token();
		memcpy(prev, &this.token, Token.sizeof);
		
		this.scan(this.token.next);
		
		this.token = *this.token.next;
		this.token.prev = prev;
		
		return &this.token;
	}
	
	void scan(Token* t) {
		t.type = Tok.None;
		t.ptr  = null;
		
		while (true) {
			if (this.ctype != Comment.None) {
				switch (*_p) {
					case '\n':
						_p++;
						this.loc.lineNum++; // TODO?
						
						if (this.ctype == Comment.Line)
							this.ctype = Comment.None;
						break;
					case '*':
						_p++;
						if (*_p == '/' && this.ctype == Comment.Star) {
							_p++;
							this.ctype = Comment.None;
						}
						break;
					case '+':
						_p++;
						if (*_p == '/' && this.ctype == Comment.Plus) {
							_p++;
							this.ctype = Comment.None;
						}
						break;
					default: _p++;
				}
				
				continue;
			}
			
			switch (*_p) {
				case 0:
				case 0x1A:
					t.type = Tok.Eof; // end of file
					return;
					
				case ' ':
				case '\t':
				case '\v':
				case '\f':
					_p++;
					continue; // skip white space
					
				case '\r':
					_p++;
					if (*_p != '\n')	// if CR stands by itself
						this.loc.lineNum++;
					continue; 			// skip white space
					
				case '\n':
					_p++;
					this.loc.lineNum++;
					continue;	// skip white space
					
				case '?': _p++; t.type = Tok.Ternary;	return;
				case '#': _p++; t.type = Tok.Hash;		return;
				case '$': _p++; t.type = Tok.Dollar; 	return;
					
				case ',': _p++; t.type = Tok.Comma; 		return;
				case ':': _p++; t.type = Tok.Colon; 		return;
				case ';': _p++; t.type = Tok.Semicolon; return;
					
				case '(': _p++; t.type = Tok.LParen; 	return;
				case ')': _p++; t.type = Tok.RParen; 	return;
				case '[': _p++; t.type = Tok.LBracket; 	return;
				case ']': _p++; t.type = Tok.RBracket; 	return;
				case '{': _p++; t.type = Tok.LCurly; 	return;
				case '}': _p++; t.type = Tok.RCurly; 	return;
				case '\\': _p++; t.type = Tok.Backslash; return;
					
				case '@':
					char* oldp = _p;
					_p++;
					
					while (std.ascii.isAlpha(*_p)) {
						_p++;
					}
					
					if (_p - oldp) {
						t.type = Tok.Property;
						t.ptr  = oldp;
						t.len  = _p - oldp;
					} else {
						t.type = Tok.At;
					}
					/*
					 switch (oldp[0 .. (_p - oldp)]) {
					 case "@property":
					 case "@safe":
					 case "@trusted":
					 case "@system":
					 case "@disable":
					 t.type = Tok.Property;
					 t.ptr  = oldp;
					 t.len  = _p - oldp;
					 default:
					 t.type = Tok.At;
					 // reset
					 _p = oldp;
					 _p++;
					 }
					 */
					return;
					
				case '=':
					_p++;
					switch (*_p) {
						case '>': _p++; t.type = Tok.GoesTo; break;
						case '=': _p++; t.type = Tok.Equals; break;
						default: t.type = Tok.Assign;
					}
					return;
					
				case '!':
					_p++;
					if (*_p == '=') {
						_p++;
						t.type = Tok.NotEquals;
					} else {
						t.type = Tok.Not;
					}
					return;
					
				case '/':
					_p++;
					switch (*_p) {
						case '/':
							_p++;
							this.ctype = Comment.Line;
							break;
						case '*':
							_p++;
							this.ctype = Comment.Star;
							break;
						case '+':
							_p++;
							this.ctype = Comment.Plus;
							break;
						case '=':
							_p++;
							t.type = Tok.DivAssign;
							break;
						default: t.type = Tok.Div;
					}
					
					if (this.ctype != Comment.None)
						continue;
					return;
					
				case '+':
					_p++;			
					if (this.ctype == Comment.Plus && *_p == '/') {
						_p++;
						this.ctype = Comment.None;
						// return;
						continue;
					}
					
					switch (*_p) {
						case '+': _p++; t.type = Tok.Increment; break;
						case '=': _p++; t.type = Tok.PlusAssign; break;
						default: t.type = Tok.Plus;
					}
					return;
					
				case '-':
					_p++;
					switch (*_p) {
						case '-': _p++; t.type = Tok.Decrement; break;
						case '=': _p++; t.type = Tok.MinusAssign; break;
						default: t.type = Tok.Minus;
					}
					return;
					
				case '*':
					_p++;
					if (this.ctype == Comment.Star && *_p == '/') {
						_p++;
						this.ctype = Comment.None;
						// return;
						continue;
					}
					
					if (*_p == '=') {
						_p++;
						t.type = Tok.MulAssign;
					} else {
						t.type = Tok.Star;
					}
					return;
					
				case '&':
					_p++;
					switch (*_p) {
						case '=': _p++; t.type = Tok.BitAndAssign; break;
						case '&': _p++; t.type = Tok.LogicAnd; break;
						default: t.type = Tok.BitAnd;
					}
					return;
					
				case '|':
					_p++;
					switch (*_p) {
						case '=': _p++; t.type = Tok.BitOrAssign; break;
						case '|': _p++; t.type = Tok.LogicOr; break;
						default: t.type = Tok.BitOr;
					}
					return;
					
				case '%':
					_p++;
					if (*_p == '=') {
						_p++;
						t.type = Tok.ModAssign;
					} else {
						t.type = Tok.Mod;
					}
					return;
					
				case '^':
					_p++;
					switch (*_p) {
						case '^':
							_p++;
							if (*_p == '=') {
								_p++;
								t.type = Tok.PowAssign;
							} else {
								t.type = Tok.Pow;
							}
							break;
						case '=': _p++; t.type = Tok.XorAssign; break;
						default: t.type = Tok.Xor;
					}
					return;
					
				case '<':
					_p++;
					switch (*_p) {
						case '=': _p++; t.type = Tok.LessEqual; break;
						case '<':
							_p++;
							if (*_p == '=') {
								_p++;
								t.type = Tok.ShiftLeftAssign;
							} else {
								t.type = Tok.ShiftLeft;
							}
							break;
						case '>': _p++; t.type = Tok.LessOrGreater; break;
						default: t.type = Tok.Less;
					}
					return;
					
				case '>':
					_p++;
					switch (*_p) {
						case '=': _p++; t.type = Tok.GreaterEqual; break;
						case '>':
							_p++;
							if (*_p == '=') {
								_p++;
								t.type = Tok.ShiftRightAssign;
							} else if (*_p == '>') {
								_p++;
								if (*_p == '=') {
									_p++;
									t.type = Tok.UnsignedShiftRightAssign;
								} else {
									t.type = Tok.UnsignedShiftRight;
								}
							} else {
								t.type = Tok.ShiftRight;
							}
							break;
						default: t.type = Tok.Greater;
					}
					return;
					
				case '~':
					_p++;
					if (*_p == '=') {
						_p++;
						t.type = Tok.CatAssign;
					} else {
						t.type = Tok.Tilde;
					}
					return;
					
				case '.':
					_p++;
					if (*_p == '.') {
						_p++;
						if (*_p == '.') {
							_p++;
							t.type = Tok.VarArg;
						} else {
							t.type = Tok.Slice;
						}
					} else {
						t.type = Tok.Dot;
					}
					return;
					
				case '0': .. case '9':
					t.ptr = _p;
					t.len = 0;
					
					if (*_p == '0') {
						_p++;
						
						bool loop = true;
						
						if (*_p == 'x') {
							_p++;
							
							while (loop) {
								switch (*_p) {
									case 'a': .. case 'f':
									case 'A': .. case 'F':
										_p++;
										break;
									default:
										if (std.ascii.isDigit(*_p))
											_p++;
										else
											loop = false;
								}
								
								t.len++;
							}
							
							t.type = Tok.HexLiteral;
							
							return;
						} else if (*_p == 'b') {
							_p++;
							
							while (loop) {
								switch (*_p) {
									case '0':
									case '1':
										_p++;
										break;
									default: loop = false;
								}
								
								t.len++;
							}
							
							t.type = Tok.BinaryLiteral;
							
							return;
						}/* else if (std.ascii.isDigit(*_p))
						  warning("Expected 'x' or 'b' after '0', not a number. [%c]", loc, *_p);*/
					}
					
					while (std.ascii.isDigit(*_p)) {
						if (*_p == '_' && std.ascii.isDigit(*(_p + 1))) {
							_p += 2; t.len += 2;
						}
						
						_p++; t.len++;
					}
					
					switch (*_p) {
						case '.':
							_p++;
							while (std.ascii.isDigit(*_p)) {
								_p++; t.len++;
								
								if (*_p == '_' && std.ascii.isDigit(*(_p + 1))) {
									_p += 2; t.len += 2;
								}
							}
							
							if (*_p == 'f' || *_p == 'F') {
								_p++;
								t.type = Tok.FloatLiteral;
							} else if (*_p == 'l' || *_p == 'L') {
								_p++;
								t.type = Tok.RealLiteral;
							} else {
								t.type = Tok.DoubleLiteral;
							}
							break;
							
						case 'l':
						case 'L':
							_p++;
							t.type = Tok.LongLiteral;
							break;
							
						case 'u':
						case 'U':
							_p++;
							if (*_p == 'l' || *_p == 'L') {
								_p++;
								t.type = Tok.UlongLiteral;
							} else {
								t.type = Tok.UintLiteral;
							}
							break;
							
						default: t.type = Tok.IntLiteral;
					}
					return;
					
				case '_':
				case 'A': .. case 'Z':
				case 'a': .. case 'z':
					char c = *_p;
					if ((c == 'w' || c == 'd' || c == 'c' || c == 'r') && *(_p + 1) == '"') {
						_p++;
						
						goto case '"';
					}
					
					t.ptr = _p;
					t.len = 0;
					
					while (std.ascii.isAlphaNum(*_p) || *_p == '_') {
						_p++; t.len++;
					}
					
					if (Types.contains(t.toChars()))
						t.type = Tok.Type;
					else if (Keywords.contains(t.toChars()))
						t.type = Tok.Keyword;
					else
						t.type = Tok.Identifier;
					
					debug writeln(" -> ", t.toChars());
					return;
					
				case '`':
					_p++;
					t.ptr = _p;
					t.len = 0;
					t.type = Tok.MultiLineString;
					
					while (*_p != '`') {
						_p++; t.len++;
						
						switch (*_p) {
							case '\n':
								this.loc.lineNum++;
								break;
							case '\r':
								_p++;
								if (*_p == '\n')
									this.loc.lineNum++;
								break;
							default: break;
						}
						
						if (t.len > ubyte.max)
							error("To long multi string: %s", loc, t.toChars());
					}
					
					if (*_p != '`')
						error("Unterminated multi string.", loc);
					_p++;
					
					debug writeln(" => [multi] => ", t.toChars(), ':', t.type, ":", loc);
					
					break;
					
				case 0x22:
					char c = *(_p - 1);
					_p++;
					
					switch (c) {
						case 'w':
							t.type = Tok.WStringLiteral;
							break;
						case 'd':
							t.type = Tok.DStringLiteral;
							break;
						case 'r':
							t.type = Tok.RegexStringLiteral;
							break;
						case 'c':
						default: t.type = Tok.None;
					}
					
					t.ptr = _p;
					t.len = 0;
					
					while (*_p != 0x22 && *_p != '\r' && *_p != '\n') {
						_p++; t.len++;
					}
					
					if (*_p != 0x22)
						error("Unterminated string: %s", loc, t.toChars());
					_p++;
					
					c = *_p;
					switch (c) {
						case 'w':
							_p++;
							t.type = Tok.WStringLiteral;
							break;
						case 'd':
							_p++;
							t.type = Tok.DStringLiteral;
							break;
						case 'r':
							_p++;
							t.type = Tok.RegexStringLiteral;
							break;
						case 'c':
						default:
							t.type = t.type == Tok.None ? Tok.StringLiteral : t.type;
					}
					debug writeln(" => ", t.toChars(), ':', t.type, ":", t.len);
					return;
					
				case 0x27:
					_p++;
					
					t.type = Tok.CharacterLiteral;
					t.ptr = _p;
					t.len = 0;
					
					_p++;
					if (*_p != 0x27)
						error("Unterminated char literal: %s", loc, t.toChars());
					
					_p++;
					
					return;
					
				default:
					_p++;
					return;
			}
		}
	}
}