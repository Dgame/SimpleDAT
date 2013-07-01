Check your (named) imports for unused or underused ones.
<hr />
Use:
<pre>
	--f		scan multiple or one file(s)
	--d		scan a whole path
	--use	for the minimal use (default is 1)
	--info	for used lines
</pre>
<hr />
test.d:
<pre>
module test;

import std.stdio;
import std.file : read;
public import std.string : format, strip;
import std.array : split, join, empty;

bool isEmpty(string test) {
	return test.strip().empty();
}

private void _foo() { }
</pre>

Checked with:
<code>DAT --f test.d --use 2 --info true</code>

<pre>
* test.d
        Named import std.string : format imported on line 6 is used 1 times. On lines: [18]
        Named import std.string : strip imported on line 6 is used 1 times. On lines: [12]
        Named import std.algorithm : startsWith imported on line 9 is never used.
        Named import std.algorithm : endsWith imported on line 9 is never used.
         - Therefore it is useless to import std.algorithm
        Named import std.array : split imported on line 8 is never used.
        Named import std.array : join imported on line 8 is never used.
        Named import std.array : empty imported on line 8 is used 1 times. On lines: [12]
        Named import std.file : read imported on line 5 is never used.
         - But maybe 'read' is used in other modules. [public]
</pre>

And for std/stdio.d checked with:
<code>DAT --f std/stdio.d --use 2 --info true</code>

<pre>
* std/stdio.d
        Named import std.c.stdio : FHND_WCHAR imported on line 35 is used 1 times. On lines: [2504]
</pre>