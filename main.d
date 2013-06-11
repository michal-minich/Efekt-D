module main;

import std.stdio;
import utils, common, printer, remarks, parser, interpreter, interactive;

@safe nothrow:


int main(string[] argv)
{
    remark = new Remarker(new RemarkPrinter(new StdErrPrinter));
    auto stdp = new StdOutPrinter;

    version (unittest)
        stdp.println("======== All Tests Succeeded ========");

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
