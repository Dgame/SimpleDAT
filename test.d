module test;

import std.stdio;
public {
	import std.file : read;
	import std.string : format, strip;
}
import std.array : split, join, empty;
import std.algorithm : startsWith, endsWith;

bool isEmpty(string test) {
	return test.strip().empty();
}

private void _foo() { }

string fmt() {
	string str = "one\nnew line";
	
	return format("%d.%d.%d", 0, 9, 9);
}