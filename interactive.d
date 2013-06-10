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
    EvalStrategy es;

    this (IReader reader, IPrinter printer, AsiPrinter asip)
    {
        this.reader = reader;
        this.printer = printer;
        this.asip = asip;
        interpreter =  new Interpreter;
        printBanner();
    }


    void run ()
    {
        while (true)
        {
            printer.print(">");
            auto ln = reader.readln()[0 .. $ - 1]/*trim \n*/;

            switch (ln)
            {
                case ":q":
                case ":quit":
                case ":exit":
                    return;

                case ":help":
                case ":h":
                case ":?":
                case "?":
                    printHelp();
                    break;

                case ":strict":
                    setEvalStrategy(EvalStrategy.strict);
                    break;

                case ":lax":
                    setEvalStrategy(EvalStrategy.lax);
                    break;

                default:
                    if (ln.length && ln[0] == ':')
                    {
                        printer.println("Unknown command \"" ~ ln ~ "\".");
                        printHelp();
                    }
                    else
                    {
                        runOne(ln);
                    }
            }
        }
    }


    private void runOne (dstring ln)
    {
        auto asis = parse(ln);
        auto res = interpreter.run(asis, es);
        if (res)
        {
            res.accept(asip);
            printer.println();
        }
    }


    void printBanner ()
    {
        printer.println("Corelang interactive, enter \":help\" for list of commands.");
        setEvalStrategy(EvalStrategy.strict);
    }


    void printHelp ()
    {
        printer.println(":q       Quit");
        printer.println(":strict  Error on any invalid code");
        printer.println(":lax     Try to evaluate invalid code");
    }


    void setEvalStrategy (EvalStrategy es)
    {
        this.es = es;
        printer.println("Current evaluation strategy is "d ~ es ~ ".");
    }
}