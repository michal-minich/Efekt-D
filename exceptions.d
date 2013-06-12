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


final class Thrower
{
    nothrow:

    private IExceptionPrinter ep;

    this (IExceptionPrinter ep) { this.ep = ep; }


    private void e(string name, dstring text)
    {
        ep.print(Except(lastItemInList(name, '.').toDString(), text));
    }


    void cannotEvalErrorOrMissing ()
    {
        e(__FUNCTION__, "Expression or its part has and error or is missing");
    }


    void integerOwerflow ()
    {
        e(__FUNCTION__, "Integer overflowed over maximum value");
    }


    void opeatorIsUndefined (dstring op)
    {
        e(__FUNCTION__, "Operator '" ~ op ~ "'is undefined.");
    }
}