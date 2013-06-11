module interactive;

import utils, common, parser, printer, exceptions, interpreter;

@safe nothrow:


final class Interactive
{
    nothrow:

    IReader reader;
    IPrinter printer;
    AsiPrinter asip;
    Interpreter interpreter;
    EvalStrategy es;
    Parser parser;

    this (IReader reader, IPrinter printer, ExceptionPrinter ep, AsiPrinter asip)
    {
        this.reader = reader;
        this.printer = printer;
        this.asip = asip;
        interpreter =  new Interpreter(new Thrower(ep));
        parser = new Parser;
        printBanner();
    }


    void run ()
    {
        while (true)
        {
            printer.color(Color.cyan, true);
            printer.print(">");
            printer.restoreColor();

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
                        printer.color(Color.cyan);
                        printer.println("Unknown command \"" ~ ln ~ "\".");
                        printer.restoreColor();
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
        auto asis = parser.parse(ln, es);

        auto res = interpreter.run(asis, es);
        if (res)
        {
            printer.color(Color.green);
            res.accept(asip);
            printer.restoreColor();
            printer.println();
        }
    }


    void printBanner ()
    {
        printer.color(Color.cyan);
        printer.println("Corelang interactive, enter \":help\" for list of commands.");
        setEvalStrategy(EvalStrategy.throwing);
    }


    void printHelp ()
    {
        printer.color(Color.white, true);
        printer.println(":q         Quit application");
        printer.println(":throwing  Stop evaluation with exception");
        printer.println(":strict    Propagate error to result of expression");
        printer.println(":lax       Try to evaluate invalid expressions");
        printer.restoreColor();
    }


    void setEvalStrategy (EvalStrategy es)
    {
        this.es = es;
        printer.color(Color.cyan);
        printer.println("Current evaluation strategy is "d ~ es.toDString() ~ ".");
        printer.restoreColor();
    }
}