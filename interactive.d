module interactive;

import std.file : exists;
import utils, common, ast, parser, printer, exceptions, validation, intrange, interpreter;


@safe nothrow:




final class Interactive
{
    nothrow:

    IReader reader;
    IPrinter printer;
    AsiPrinter asip;
    NameValidator nameValidator;
    Interpreter interpreter;
    EvalStrategy es;
    Parser parser;
    Thrower th;




    this (IReader reader, IPrinter printer, ExceptionPrinter ep, AsiPrinter asip)
    {
        this.reader = reader;
        this.printer = printer;
        this.asip = asip;
        th = new Thrower(ep);
        nameValidator = new NameValidator;
        interpreter =  new Interpreter(th);
        parser = new Parser;
        printBanner();
        enum ar = "autorun.ef";
        if (ar.fileExists())
            runEfFile(ar);
    }




    void run ()
    {
        while (true)
        {
            printer.color(evalStrategyColor(es), evalStrategyBold(es));
            printer.print(">");
            printer.restoreColor();

            auto ln = reader.readln()[0 .. $ - 1]/*trim \n*/;

            switch (ln.sliceBefore(' ').toLowerAscii())
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
                case ":t":
                    setEvalStrategy(EvalStrategy.throwing);
                    break;

                case ":strict":
                case ":s":
                    setEvalStrategy(EvalStrategy.strict);
                    break;

                case ":lax":
                case ":l":
                    setEvalStrategy(EvalStrategy.lax);
                    break;

                case ":load":
                    auto filePath = ln.sliceAfter(' ');
                    if (filePath.length && !(filePath.length >= 3 && filePath[$ - 3 .. $].toLowerAscii() == ".ef"))
                        filePath ~= ".ef";

                    runEfFile(filePath);
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
                        run(ln);
                    }
            }
        }
    }




    private void runEfFile (dstring filePath)
    {
        interpreter = new Interpreter(th);

        try
        {
            auto code = loadFile(filePath.toString(), th);

            auto es2 = EvalStrategy.strict;
            auto asis = parser.parse(code, es2);
            nameValidator.validate(asis, es2);
            (new IntRange(interpreter)).calculate(asis, es2);
            (new AsiPrinter(new FilePrinter((filePath[0 .. $ - 3] ~ ".range.txt").toString())))
                .print(asis, true);
            interpreter.run(asis, es2);
        }
        catch (InterpreterException ex)
        {
            // do nothing
        }
        catch (Exception ex)
        {
            printer.print(ex.msg.toDString());
        }
    }




    private void run (dstring code)
    {
        auto asis = parser.parse(code, es);
        run (asis);
    }




    private void run (Asi[] asis)
    {
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
        printer.print("Programming language ");
        printer.color(Color.cyan, true);
        printer.println("Efekt");
        printer.color(Color.cyan);
        printer.println("Enter \":help\" for list of commands.");
    }




    void printHelp ()
    {
        printer.color(Color.white, true);
        printer.println(":q           Quit application");
        printer.println(":throwing    Stop evaluation with exception");
        printer.println(":strict      Propagate error to result of expression");
        printer.println(":lax         Try to evaluate invalid expressions");
        printer.println(":load <file> Run program from file");
        printer.restoreColor();
    }




    void setEvalStrategy (EvalStrategy es)
    {
        this.es = es;

        printer.color(Color.cyan);
        printer.print("Current evaluation strategy is ");

        printer.color(evalStrategyColor(es), evalStrategyBold(es));
        printer.print(es.toDString());

        printer.color(Color.cyan);
        printer.println(".");

        printer.restoreColor();
    }




    Color evalStrategyColor (EvalStrategy es)
    {
        final switch (es) with (EvalStrategy) 
        {
            case throwing: return Color.cyan;
            case strict: return Color.magenta;
            case lax: return Color.yellow;
        }
    }




    bool evalStrategyBold (EvalStrategy es)
    {
        final switch (es) with (EvalStrategy) 
        {
            case throwing: return true;
            case strict: return true;
            case lax: return true;
        }
    }
}




@trusted bool fileExists (string path)
{
    try
    {
        return exists(path);
    }
    catch (Exception ex)
    {
        assert (false);
    }
}