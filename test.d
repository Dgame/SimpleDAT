module test;

import std.stdio;
public {
	import std.file : read;
	import std.string : format, strip;
}
import std.array : split, join, empty;
import std.algorithm : startsWith, endsWith;

bool isEmpty(string test) {
	const uint N = 0x000000ff;
	return test.strip().empty();
}

private void _foo() { }