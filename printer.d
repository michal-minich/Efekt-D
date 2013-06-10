module printer;

import common, ast;

@safe nothrow:



final class AsiPrinter : AsiVisitor!void
{
    nothrow:

    IPrinter printer;


    this (IPrinter printer) { this.printer = printer; }


    void visit (Var v)
    {
        printer.print("var ");
        printer.print(v.text);
        printer.print(" = ");
        v.value.accept(this);
    }


    void visit (Missing m)
    {
        printer.print("<missing>");
    }


    void visit (Err er)
    {
        printer.print("<error ");
        er.asi.accept(this);
        printer.print(">");
    }


    void visit (Int i)
    {
        printer.print(i.text);
    }


    void visit (OpApply opa)
    {
        opa.op1.accept(this);
        printer.print(" ");
        printer.print(opa.text);
        printer.print(" ");
        opa.op2.accept(this);
    }
}