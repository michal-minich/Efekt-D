module main;

import std.stdio;
import utils, common, printer, parser, interpreter;

@safe nothrow:


int main(string[] argv)
{
    auto stdp = new StdOutPrinter;
    errp = new ErrorPrinter(stdp);
    asip = new AsiPrinter(stdp);

    auto asis = parse("2+1");

    foreach (a; asis)
    {
        a.accept(asip);
        stdp.println();
    }

    auto intp = new Interpreter;
    auto res = intp.run(asis);
    if (res)
        res.accept(asip);

    readLine();

    return 0;
}


@trusted void readLine()
{
    dontThrow(readln());
}
