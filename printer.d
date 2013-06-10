module printer;

import utils, common, ast;

@safe nothrow:



final class AsiPrinter : AsiVisitor!void
{
    nothrow:

    IPrinter printer;


    this (IPrinter printer) { this.printer = printer; }


    void visit (Var v)
    {
        printer.print("var ");
        printer.print(v.name);
        printer.print(" = ");
        v.value.accept(this);
    }


    void visit (Missing m)
    {
        printer.print("<missing>");
    }


    void visit (Err er)
    {
        printer.print("<error");
        if (er.asi)
        {
            printer.print(" ");
            er.asi.accept(this);
        }
        printer.print(">");
    }


    void visit (Int i)
    {
        printer.print(i.asLong.toDString());
    }


    void visit (OpApply opa)
    {
        opa.op1.accept(this);
        printer.print(" ");
        printer.print(opa.op);
        printer.print(" ");
        opa.op2.accept(this);
    }
}