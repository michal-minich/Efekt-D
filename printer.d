module printer;

import utils, common, ast;

@safe nothrow:



final class AsiPrinter : AsiVisitor!void
{
    nothrow:

    IPrinter printer;


    this (IPrinter printer) { this.printer = printer; }

    
    void print (Asi[] asis)
    {
        if (!asis)
            return;

        foreach (a; asis[0 ..$ - 1])
        {
            a.accept(this);
            printer.println();
        }

        asis[$ - 1].accept(this);
    }


    void visit (Var v)
    {
        printer.print("var ");
        if (v.exp)
            v.exp.accept(this);
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


    void visit (Ident i)
    {
        printer.print(i.name);
    }


    void visit (Assign a)
    {
        printer.print(a.name);
        printer.print(" = ");
        a.value.accept(this);
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