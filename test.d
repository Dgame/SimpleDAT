module test;

import std.stdio;
import std.file : read;
public import std.string : format, strip;
import std.array : split, join, empty;

bool isEmpty(string test) {
	return test.strip().empty();
}

private void _foo() { }