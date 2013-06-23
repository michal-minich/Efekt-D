module exceptions;

import utils, common;

@safe nothrow:


interface IExceptionPrinter
{
    nothrow void print (Except ex);
}


struct Except
{
    dstring name;
    dstring text;
}


final class ExceptionPrinter : IExceptionPrinter
{
    nothrow:

    private IPrinter printer;

    this (IPrinter printer) { this.printer = printer; }

    void print (Except ex)
    {
        printer.print("Exception: [");
        printer.print(ex.name);
        printer.print("] ");
        printer.println(ex.text);
    }
}    


final class ExceptionCollector : IExceptionPrinter
{
    nothrow:

    Except[] exceptions;

    void print (Except ex) { exceptions ~= ex; }
    void clear () { exceptions = null; }
}


final class InterpreterException : Exception
{
    nothrow:
    this (string msg) { super (msg); }
}


final class Thrower
{
    private IExceptionPrinter ep;
    EvalStrategy evalStrategy;

    nothrow this (IExceptionPrinter ep) { this.ep = ep; }


    private void e(string name, dstring text)
    {
        auto lastName = lastItemInList(name, '.');
        ep.print(Except(lastName.toDString(), text));
        if (evalStrategy == EvalStrategy.throwing)
            throw new InterpreterException("[" ~ lastName ~ "] " ~ text.toString());
    }


    void cannotEvalError ()
    {
        e(__FUNCTION__, "Expression or its part has and error");
    }

    void cannotEvalMissing ()
    {
        e(__FUNCTION__, "Expression or its part is missing");
    }

    void integerOwerflow ()
    {
        e(__FUNCTION__, "Integer overflowed over maximum value");
    }

    void integerUnderflow ()
    {
        e(__FUNCTION__, "Integer underflowed over minimum value");
    }

    void opeatorIsUndefined (dstring op)
    {
        e(__FUNCTION__, "Operator '" ~ op ~ "' is undefined.");
    }

    void undefinedVariable (dstring op)
    {
        e(__FUNCTION__, "Variable '" ~ op ~ "' is undefined.");
    }

    void cannotLoadFile (dstring path, Exception ex)
    {
        e(__FUNCTION__, "Failed to load file '" ~ path ~ "': " ~ ex.msg.toDString());
    }
}