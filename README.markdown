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
Named import std.string : format imported on line 5 is never used.
 But maybe 'format' is used in other modules. [public]
Named import std.string : strip imported on line 5 is used 1 times. On lines: [9
]
Named import std.array : split imported on line 6 is never used.
Named import std.array : join imported on line 6 is never used.
Named import std.array : empty imported on line 6 is used 1 times. On lines: [9]

Named import std.file : read imported on line 4 is never used.
</pre>

And for std/stdio.d checked with:
<code>DAT --f std/stdio.d --use 2 --info true</code>

<pre>
Named import std.c.stdio : FHND_WCHAR imported on line 35 is used 1 times. On lines: [2504]
</pre>