module common;

import std.stdio;
import utils, common, printer, remarks;

@safe nothrow:

Remarker remark;
AsiPrinter asip;


enum EvalStrategy { strict, lax }


interface IReader
{
    nothrow:
    dstring readln ();
}


interface IPrinter
{
    nothrow:

    void print (dstring);
    void println (dstring);
    void println ();
}


final class StdInReader : IReader
{
    nothrow:
    @trusted dstring readln () { return dontThrow(std.stdio.readln().toDString()); }
}


final class StdOutPrinter : IPrinter
{
    nothrow:

    @trusted void print (dstring s) { dontThrow(write(s)); }
    @trusted void println (dstring s) { dontThrow(writeln(s)); }
    @trusted void println () { dontThrow(writeln()); }
}


final class StdErrPrinter : IPrinter
{
    nothrow:

    @trusted void print (dstring s) { dontThrow(stderr.write(s)); }
    @trusted void println (dstring s) { dontThrow(stderr.writeln(s)); }
    @trusted void println () { dontThrow(stderr.writeln()); }
}


final class StringPrinter : IPrinter
{
    nothrow:
    dstring str;

    void clear () { str = null; }
    void print (dstring s) { str ~= s; }
    void println (dstring s) { str ~= s ~ '\n'; }
    void println () { str ~= '\n'; }
}