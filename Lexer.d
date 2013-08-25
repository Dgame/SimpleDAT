module DAT.Lexer;

import std.stdio;
import std.string : format, splitLines;
import std.file : exists, read;
import std.c.string : memcpy;
import std.ascii : isAlpha, isAlphaNum, isDigit;

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

const struct Pair {
public:
	uint id;
	string value;
}

enum Keyword {
	None,
	abstract_, alias_, align_, asm_, assert_, auto_,
	body_, break_,
	case_, cast_, catch_, cdouble_, class_, const_, continue_,
	debug_, default_, delegate_, delete_, deprecated_, do_,
	else_, enum_, export_, extern_,
	false_, final_, finally_, for_, foreach_, foreach_reverse_, function_,
	goto_,
	if_, immutable_, import_, in_, inout_, interface_, invariant_, is_,
	lazy_,
	macro_, mixin_, module_, new_, nothrow_, null_,
	out_, override_,
	package_, pragma_, private_, protected_, public_, pure_,
	ref_, return_,
	scope_, shared_, static_, struct_, super_, switch_, synchronized_,
	template_, this_, throw_, true_, try_, typedef_, typeid_, typeof_,
	union_, unittest_,
	version_, volatile_,
	while_, with_,
	_file_, _module_, _line_, _function_, _pretty_function_,
	gshared_, traits_, vector_, parameters_, _date_, _eof_,
	_time_, _timestamp_, _vendor_, _version_
}

private static immutable Pair[][26] Keywords = 
	[[Pair(Keyword.abstract_, "abstract"), Pair(Keyword.alias_, "alias"),
	  Pair(Keyword.align_, "align"), Pair(Keyword.asm_, "asm"),
	  Pair(Keyword.assert_, "assert"), Pair(Keyword.auto_, "auto")],
	 [Pair(Keyword.body_, "body"), Pair(Keyword.break_, "break")],
	 [Pair(Keyword.case_, "case"), Pair(Keyword.cast_, "cast"),
	 Pair(Keyword.catch_, "catch"), Pair(Keyword.cdouble_, "cdouble"),
	 Pair(Keyword.class_, "class"), Pair(Keyword.const_, "const"),
	 Pair(Keyword.continue_, "continue")],
	 [Pair(Keyword.debug_, "debug"), Pair(Keyword.default_, "default"),
	 Pair(Keyword.delegate_, "delegate"), Pair(Keyword.delete_, "delete"),
	 Pair(Keyword.deprecated_, "deprecated"), Pair(Keyword.do_, "do")],
	 [Pair(Keyword.else_, "else"), Pair(Keyword.enum_, "enum"),
	 Pair(Keyword.export_, "export"), Pair(Keyword.extern_, "extern")],
	 [Pair(Keyword.false_, "false"), Pair(Keyword.final_, "final"),
	 Pair(Keyword.finally_, "finally"), Pair(Keyword.for_, "for"),
	 Pair(Keyword.foreach_, "foreach"),
	 Pair(Keyword.foreach_reverse_, "foreach_reverse"),
	 Pair(Keyword.function_, "function")],
	 [Pair(Keyword.goto_, "goto")],
	 null, /// h
	 [Pair(Keyword.if_, "if"), Pair(Keyword.immutable_, "immutable"),
	 Pair(Keyword.import_, "import"), Pair(Keyword.in_, "in"),
	 Pair(Keyword.inout_, "inout"), Pair(Keyword.interface_, "interface"),
	 Pair(Keyword.invariant_, "invariant"), Pair(Keyword.is_, "is")],
	 null, /// j
	 null, /// k
	 [Pair(Keyword.lazy_, "lazy")],
	 [Pair(Keyword.macro_, "macro"), Pair(Keyword.mixin_, "mixin"),
	 Pair(Keyword.module_, "module")],
	 [Pair(Keyword.new_, "new"),
	 Pair(Keyword.nothrow_, "nothrow"), Pair(Keyword.null_, "null")],
	 [Pair(Keyword.out_, "out"), Pair(Keyword.override_, "override")],
	 [Pair(Keyword.package_, "package"), Pair(Keyword.pragma_, "pragma"),
	 Pair(Keyword.private_, "private"), Pair(Keyword.protected_, "protected"),
	 Pair(Keyword.public_, "public"), Pair(Keyword.pure_, "pure")],
	 null, /// q
	 [Pair(Keyword.ref_, "ref"), Pair(Keyword.return_, "return")],
	 [Pair(Keyword.scope_, "scope"), Pair(Keyword.shared_, "shared"),
	 Pair(Keyword.static_, "static"), Pair(Keyword.struct_, "struct"),
	 Pair(Keyword.super_, "super"), Pair(Keyword.switch_, "switch"),
	 Pair(Keyword.synchronized_, "synchronized")],
	 [Pair(Keyword.template_, "template"), Pair(Keyword.this_, "this"),
	 Pair(Keyword.throw_, "throw"), Pair(Keyword.true_, "true"),
	 Pair(Keyword.try_, "try"), Pair(Keyword.typedef_, "typedef"),
	 Pair(Keyword.typeid_, "typeid"), Pair(Keyword.typeof_, "typeof")],
	 [Pair(Keyword.union_, "union"), Pair(Keyword.unittest_, "unittest")],
	 [Pair(Keyword.version_, "version"), Pair(Keyword.volatile_, "volatile")],
	 [Pair(Keyword.while_, "while"), Pair(Keyword.with_, "with")],
	 null, /// x
	 null, /// y
	 [Pair(Keyword._file_, "__FILE__"), Pair(Keyword._module_, "__MODULE__"),
	 Pair(Keyword._line_, "__LINE__"), Pair(Keyword._function_, "__FUNCTION__"),
	 Pair(Keyword._pretty_function_, "__PRETTY_FUNCTION__"),
	 Pair(Keyword.gshared_, "__gshared"), Pair(Keyword.traits_, "__traits"),
	 Pair(Keyword.vector_, "__vector"), Pair(Keyword.parameters_, "__parameters"),
	 Pair(Keyword._date_, "__DATE__"), Pair(Keyword._eof_, "__EOF__"),
	 Pair(Keyword._time_, "__TIME__"), Pair(Keyword._timestamp_, "__TIMESTAMP__"),
	 Pair(Keyword._vendor_, "__VENDOR__"), Pair(Keyword._version_, "__VERSION__")]];

enum Type {
	None,
	void_,
	bool_,
	byte_, ubyte_,
	short_, ushort_,
	int_, uint_,
	long_, ulong_,
	cent_, ucent_,
	float_, double_,
	real_,
	ifloat_, idouble_,
	ireal_,
	cfloat_, cdouble_,
	creal_,
	char_, wchar_, dchar_,
	string_, wstring_, dstring_,
	ptrdiff_t_
}

private static immutable Pair[][26] Types = 
	[null, /// a
	 [Pair(Type.bool_, "bool"), Pair(Type.byte_, "byte")],
	 [Pair(Type.cent_, "cent"), Pair(Type.cfloat_, "cfloat"),
	 Pair(Type.cdouble_, "cdouble"), Pair(Type.creal_, "creal"),
	 Pair(Type.char_, "char")],
	 [Pair(Type.double_, "double"), Pair(Type.dchar_, "dchar"),
	 Pair(Type.dstring_, "dstring")],
	 null, /// e
	 [Pair(Type.float_, "float")],
	 null, /// g
	 null, /// h
	 [Pair(Type.ifloat_, "ifloat"), Pair(Type.idouble_, "idouble"),
	 Pair(Type.int_, "int"), Pair(Type.ireal_, "ireal")],
	 null, /// j
	 null, /// k
	 [Pair(Type.long_, "long")],
	 null, /// m
	 null, /// n
	 null, /// o
	 [Pair(Type.ptrdiff_t_, "ptrdiff_t")],
	 null, /// q
	 [Pair(Type.real_, "real")],
	 [Pair(Type.short_, "short"), Pair(Type.string_, "string")],
	 null, /// t
	 [Pair(Type.ubyte_, "ubyte"), Pair(Type.ushort_, "ushort"),
	 Pair(Type.uint_, "uint"), Pair(Type.ulong_, "ulong"),
	 Pair(Type.ucent_, "ucent")],
	 [Pair(Type.void_, "void")],
	 [Pair(Type.wchar_, "wchar"), Pair(Type.wstring_, "wstring")],
	 null, /// x
	 null, /// y
	 null /// z
	 ];

private const(Pair)* contains(ref immutable Pair[][26] array, const char[] value) {
	int c = -1;
	if (value[0] != '_')
		c = value[0] - 'a';
	else
		c = 25;
	
	if (c < 0 || c > 26)
		return null;
	
	foreach (ref const Pair pair; array[c]) {
		if (pair.value == value)
			return &pair;
	}
	
	return null;
}

private string getTokenValue(Tok tok) pure nothrow {
	return tok < tokenValues.length ? tokenValues[tok] : "Undefinied Tok";
}

enum Mod {
	None = 0,
	Pure = 1,
	Const = 2,
	Immutable = 4,
	Nothrow = 8,
	Ref = 0x10
}

struct Lexem {
public:
	immutable(char)* ptr;		 // pointer to first character of this token within buffer
	uint length;
	
	const(char)[] toChars() const pure nothrow {
		return this.ptr ? this.ptr[0 .. this.length] : "Invalid";
	}
}

struct Token {
public:
	Token* next;
	Token* previous;
	
	Lexem lexem;
	const(Pair)* pair;
	
	Tok type;
	
	const(char)[] toChars() const pure nothrow {
		if (this.isKeyword() || this.isType())
			return this.pair.value;
		
		return this.lexem.length ? this.lexem.toChars() : getTokenValue(this.type);
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
	uint lineNum;
	
	this(string filename, uint line) {
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

void error(Args...)(ref const Loc loc, string msg, Args args) {
	static if (args.length != 0) {
		msg = format(msg, args);
	}
	
	throw new Exception(msg, loc.filename, loc.lineNum);
}

enum LS = 0x2028;	   // UTF line separator
enum PS = 0x2029;	   // UTF paragraph separator

struct Lexer {
	const uint _maxLines;
	string _content;
	
	Loc loc; // for error messages
	immutable(char)* _p; // current character
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
		
		this.loc = Loc(filename, 1);
		
		this._content = cast(string) read(filename);
		this._maxLines = this._content.splitLines().length;
		
		_p = &this._content[0];
		
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
		if (this.token.next) {
			this.token = *this.token.next;
			
			goto L1;
		}
		
		Token prev = this.token;
		
		Token t;
		this.scan(&t);
		
		prev.next = new Token();
		memcpy(prev.next, &t, Token.sizeof);
		
		this.token = t;
		
		this.token.previous = new Token();
		memcpy(this.token.previous, &prev, Token.sizeof);
		
		version(none) {
			writeln("----");
			writeln(prev.toChars(), "::", prev.next.toChars());
			writeln(this.token.toChars());
			writeln(this.token.previous.toChars(), "::", this.token.previous.next.toChars());
		}
		
	L1:
		return &this.token;
	}
	
	Token* skipParents() {
		assert(this.token.type == Tok.LParen);
		
		while (this.token.type != Tok.RParen) {
			this.nextToken();
		}
		
		return this.nextToken();
	}
	
	Mod parseModifier() {
		Mod mod;
		
		do {
			if (!this.token.isKeyword() || this.peekAhead().type == Tok.LParen)
				break;
			
			switch (this.token.pair.id) {
				case Keyword.pure_:
					mod |= Mod.Pure;
					break;
				case Keyword.const_:
					mod |= Mod.Const;
					break;
				case Keyword.immutable_:
					mod |= Mod.Immutable;
					break;
				case Keyword.nothrow_:
					mod |= Mod.Nothrow;
				default: break;
			}
			
			this.nextToken();
		} while (mod != Mod.None);
		
		return mod;
	}
	
	Token* peekAhead() {
		if (!this.token.next)
			this.token.next = new Token();
		
		this.scan(this.token.next);
		
		this.token.next.previous = new Token();
		memcpy(this.token.next.previous, &this.token, Token.sizeof);
		
		return this.token.next;
	}
	
	Token* peekAhead2() {
		Token* t = this.peekAhead();
		
		if (!t.next)
			t.next = new Token();
		else
			goto L1;
		
		this.scan(t.next);
		
		t.next.previous = new Token();
		memcpy(t.next.previous, t, Token.sizeof);
		
	L1:
		return t.next;
	}
	
	void scan(Token* t) {
		while (true) {
			if (loc.lineNum >= this._maxLines) {
				t.type = Tok.Eof;
				
				return;
			}
			
			/// Look for the end of the comment
			if (this.ctype != Comment.None) {
				switch (*_p) {
					case '\n':
						_p++;
						this.loc.lineNum++;
						
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
					
				case ',': _p++; t.type = Tok.Comma; 	return;
				case ':': _p++; t.type = Tok.Colon; 	return;
				case ';': _p++; t.type = Tok.Semicolon; return;
					
				case '(': _p++; t.type = Tok.LParen; 	return;
				case ')': _p++; t.type = Tok.RParen; 	return;
				case '[': _p++; t.type = Tok.LBracket; 	return;
				case ']': _p++; t.type = Tok.RBracket; 	return;
				case '{': _p++; t.type = Tok.LCurly; 	return;
				case '}': _p++; t.type = Tok.RCurly; 	return;
				case '\\': _p++; t.type = Tok.Backslash; return;
					
				case '@':
					immutable(char)* oldp = _p;
					_p++;
					
					while (isAlpha(*_p)) {
						_p++;
					}
					
					if (_p - oldp) {
						t.type = Tok.Property;
						t.lexem = Lexem(oldp, _p - oldp);
					} else {
						t.type = Tok.At;
					}
					
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
					/// Look for comments
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
					t.lexem = Lexem(_p, 0);
					
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
										if (isDigit(*_p))
											_p++;
										else
											loop = false;
								}
								
								t.lexem.length++;
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
								
								t.lexem.length++;
							}
							
							t.type = Tok.BinaryLiteral;
							
							return;
						}
						
						_p--; /// To catch single 0's
					}
					
					while (isDigit(*_p)) {
						if (*_p == '_' && isDigit(*(_p + 1))) {
							_p += 2;
							t.lexem.length += 2;
						}
						
						_p++;
						t.lexem.length++;
					}
					
					switch (*_p) {
						case '.':
							_p++;
							while (isDigit(*_p)) {
								_p++; t.lexem.length++;
								
								if (*_p == '_' && isDigit(*(_p + 1))) {
									_p += 2;
									t.lexem.length += 2;
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
					Lexem lexem = Lexem(_p, 0);
					
					while (isAlphaNum(*_p) || *_p == '_') {
						_p++;
						lexem.length++;
					}
					
					if (const Pair* pa = Types.contains(lexem.toChars())) {
						t.type = Tok.Type;
						t.pair = pa;
					} else if (const Pair* pa = Keywords.contains(lexem.toChars())) {
						t.type = Tok.Keyword;
						t.pair = pa;
					} else {
						t.type = Tok.Identifier;
						t.lexem = lexem;
					}
					
					//debug writeln("ID: -> ", t.toChars());
					
					return;
					
				case '"':
					_p++;
					
					t.type = Tok.StringLiteral;
					t.lexem = Lexem(_p, 0);
					
					while (*_p != '"') {
						if (*_p == 0x5C) {
							_p++;
							t.lexem.length++;
						}
						
						if (*_p == '\n')
							error(loc, "NL in string");
						
						_p++;
						t.lexem.length++;
					}
					
					//debug writeln("String@(", loc.lineNum, "): -> ", t.toChars());
					
					if (*_p != '"')
						error(loc, "Unterminated string: %s -> %c", t.toChars(), *_p);
					
					_p++;
					
					return;
					
				case 0x27:
					_p++;
					
					t.type = Tok.CharacterLiteral;
					t.lexem = Lexem(_p, 0);
					
					while (*_p != 0x27) {
						if (*_p == 0x5C) {
							_p++;
							t.lexem.length++;
						}
						
						_p++;
						t.lexem.length++;
					}
					
					if (*_p != 0x27)
						error(loc, "Unterminated char: %s -> %c", t.toChars(), *_p);
					
					_p++;
					
					return;
					
				default:
					_p++;
					
					return;
			}
		}
	}
}