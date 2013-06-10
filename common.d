module common;

import std.stdio;
import utils, common;

@safe nothrow:


interface IPrinter
{
    nothrow:

    void print (dstring);
    void println (dstring);
}


class ConsolePrinter : IPrinter
{
    nothrow:

    @trusted void print (dstring s) { dontThrow(write(s)); }
    @trusted void println (dstring s) { dontThrow(writeln(s)); }
}