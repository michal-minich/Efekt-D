module common;

import std.stdio;
import utils, common, printer;

@safe nothrow:


ErrorPrinter errp;
AsiPrinter asip;


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

    void reset () { str = null; }
    void print (dstring s) { str ~= s; }
    void println (dstring s) { str ~= s ~ '\n'; }
    void println () { str ~= '\n'; }
}


final class ErrorPrinter
{
    nothrow:

    IPrinter printer;

    this (IPrinter printer) { this.printer = printer; }

    void notice (dstring s) { printer.println ("Notice: " ~ s); }
    void warn (dstring s) { printer.println ("Warning: " ~ s); }
    void error (dstring s) { printer.println ("Error: " ~ s); }
    void blocker (dstring s) { printer.println ("Blocker: " ~ s); }
}