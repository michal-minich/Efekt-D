module common;

import std.file, std.stdio;
import terminal;
import utils, printer, remarks, exceptions;

public import terminal : Color; 



@system dstring loadFile (string path, Thrower th)
{
    try
    {
        return std.file.readText(path).toDString();
    }
    catch (Exception ex)
    {
        th.cannotLoadFile(path.toDString(), ex);
        return null;
    }
}


@safe nothrow:


Remarker remark;
AsiPrinter asip;


enum EvalStrategy { throwing, strict, lax }


interface IReader
{
    nothrow:
    dstring readln ();
}


interface IBasicPrinter
{
    nothrow:

    void print (dstring);
    void println (dstring);
    void println ();
}


interface IPrinter : IBasicPrinter
{
    nothrow:

    void color (Color c, bool bold = false);
    void restoreColor ();
}


final class StdInReader : IReader
{
    nothrow:
    @trusted dstring readln () { return dontThrow(std.stdio.readln().toDString()); }
}


@trusted setColor (alias t) (Color color, bool bold)
{
    try
    {
        t.bold = bold;
        t.foregroundColor(color);
    }
    catch (Exception ex)
    {
        assert(ex.msg);
    }
}


@trusted colorPrintLn (alias t, alias f) (Color color, bool bold, dstring s, bool println = true)
{
    try
    {
        t.bold = bold;
        scope(exit) t.bold = false;

        auto oldColor = t.foregroundColor(color);
        scope(exit) t.foregroundColor(oldColor);

        if (println)
            f.writeln(s);
        else
            f.write(s);
    }
    catch (Exception ex)
    {
        assert(ex.msg);
    }
}


@trusted colorPrint (alias t, alias f) (Color color, bool bold, dstring s)
{
    colorPrintLn!(t, f)(color, bold, s, false);
}


final class StdOutPrinter : IPrinter
{
    nothrow:

    @trusted void color (Color c, bool bold = false)
    {
        setColor!(terminal.stdout)(c, bold);
    }

    void restoreColor ()
    {
        color(Color.white, false);
    }

    @trusted void print (dstring s) { dontThrow(write(s)); }
    @trusted void println (dstring s) { dontThrow(writeln(s)); }
    @trusted void println () { dontThrow(writeln()); }
}


final class StdErrPrinter : IPrinter
{
    nothrow:

    Color clr;
    bool bold;

    this (Color color, bool bold = false) { clr = color; this.bold = bold; }

    @trusted void color (Color c, bool bold = false)
    {
        setColor!(terminal.stderr)(c, bold);
    }

    void restoreColor ()
    {
        color(Color.white, false);
    }

    @trusted void print (dstring s)
    {
        colorPrint!(terminal.stderr, std.stdio.stderr)(clr, bold, s);
    }

    @trusted void println (dstring s)
    {
        colorPrintLn!(terminal.stderr, std.stdio.stderr)(clr, bold, s);
    }

    @trusted void println () { dontThrow(std.stdio.stderr.writeln()); }
}


final class StringPrinter : IPrinter
{
    nothrow:
    dstring str;

    void color (Color c, bool bold = false) {}
    void restoreColor () {}
    void clear () { str = null; }
    void print (dstring s) { str ~= s; }
    void println (dstring s) { str ~= s ~ '\n'; }
    void println () { str ~= '\n'; }
}