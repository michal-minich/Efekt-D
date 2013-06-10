module main;

import std.stdio;
import utils, common, printer, parser;

@safe nothrow:


int main(string[] argv)
{
    auto asis = parse("2+1");

    auto p = new AsiPrinter(new ConsolePrinter);

    foreach (a; asis)
        a.accept(p);

    readLine();

    return 0;
}


@trusted void readLine()
{
    dontThrow(readln());
}
