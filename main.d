module main;

import std.stdio;
import utils, common, printer, parser, interpreter, interactive;

@safe nothrow:


int main(string[] argv)
{
    errp = new ErrorPrinter(new StdErrPrinter);
    auto stdp = new StdOutPrinter;

    auto interactive = new Interactive(
         new StdInReader,
         stdp, 
         new AsiPrinter(stdp));

    interactive.run();

    return 0;
}


@trusted void readLine()
{
    dontThrow(readln());
}
