module printer;

import common, ast;

@safe nothrow:



final class AsiPrinter : AsiVisitor!void
{
    nothrow:

    IPrinter printer;

    this (IPrinter printer) { this.printer = printer; }

    void visit (Int i)
    {
        printer.print(i.text);
    }

    void visit (OpApply opa)
    {
        opa.op1.accept(this);
        printer.print( opa.text);
        opa.op2.accept(this);
    }
}