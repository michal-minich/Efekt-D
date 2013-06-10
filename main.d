module main;

import std.stdio;
import utils, common, printer, parser;

@safe nothrow:


int main(string[] argv)
{
    auto stdp = new StdOutPrinter;
    errp = new ErrorPrinter(stdp);
    asip = new AsiPrinter(stdp);

    auto asis = parse("+1");

    foreach (a; asis)
        a.accept(asip);

    readLine();

    return 0;
}


@trusted void readLine()
{
    dontThrow(readln());
}
