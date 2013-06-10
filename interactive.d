module interactive;

import common, parser, printer, interpreter;

@safe nothrow:


final class Interactive
{
    nothrow:

    IReader reader;
    IPrinter printer;
    AsiPrinter asip;
    Interpreter interpreter;

    this (IReader reader, IPrinter printer, AsiPrinter asip)
    {
        this.reader = reader;
        this.printer = printer;
        this.asip = asip;
        interpreter =  new Interpreter;
        printBanner();
    }


    void printBanner ()
    {
        printer.print("Corelang interactive, enter \":q\" to quit.");
    }


    void run ()
    {
        while (true)
        {
            printer.println();
            printer.print(">");
            auto ln = reader.readln()[0 .. $ - 1]/*trim \n*/;

            switch (ln)
            {
                case ":q":
                    return;

                default:
                    runOne(ln);
            }
        }
    }


    private void runOne (dstring ln)
    {
        auto asis = parse(ln);
        auto res = interpreter.run(asis);
        if (res)
            res.accept(asip);
    }
}