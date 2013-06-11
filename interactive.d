module interactive;

import common, parser, printer, exceptions, interpreter;

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
        interpreter =  new Interpreter(new Thrower(new ExceptionPrinter(printer)));
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

                case ":throwing":
                    setEvalStrategy(EvalStrategy.throwing);
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
        auto asis = parse(ln, es);
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
        setEvalStrategy(EvalStrategy.throwing);
    }


    void printHelp ()
    {
        printer.println(":q         Quit application");
        printer.println(":throwing  Stop evaluation with exception");
        printer.println(":strict    Propagate error to result of expression");
        printer.println(":lax       Try to evaluate invalid expressions");
    }


    void setEvalStrategy (EvalStrategy es)
    {
        this.es = es;
        printer.println("Current evaluation strategy is "d ~ es ~ ".");
    }
}