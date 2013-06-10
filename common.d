module common;

import std.stdio;
import utils, common, printer;

@safe nothrow:


ErrorPrinter errp;
AsiPrinter asip;


interface IPrinter
{
    nothrow:

    void print (dstring);
    void println (dstring);
}


final class StdOutPrinter : IPrinter
{
    nothrow:

    @trusted void print (dstring s) { dontThrow(write(s)); }
    @trusted void println (dstring s) { dontThrow(writeln(s)); }
}


final class StdErrPrinter : IPrinter
{
    nothrow:

    @trusted void print (dstring s) { dontThrow(stderr.write(s)); }
    @trusted void println (dstring s) { dontThrow(stderr.writeln(s)); }
}


final class StringPrinter : IPrinter
{
    nothrow:
    dstring str;

    void reset () { str = null; }
    @trusted void print (dstring s) { str ~= s; }
    @trusted void println (dstring s) { str ~= s ~ '\n'; }
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