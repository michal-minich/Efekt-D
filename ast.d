module ast;


@safe nothrow:


import printer;


interface AsiVisitor (R)
{
    nothrow:

    R visit (Int);
    R visit (OpApply);
}


mixin template Acceptors ()
{
    override void accept (AsiPrinter v) { v.visit(this); }
}

abstract class  Asi
{
    nothrow:
    dstring text;
    this (dstring txt) { text = txt; }
    void accept (AsiPrinter);
}


abstract class Exp : Asi
{
    nothrow:
    this (dstring txt) { super (txt); }
}


final class Int : Exp
{
    nothrow:
    this (dstring txt) { super (txt); }
    mixin Acceptors!();
}


final class OpApply : Exp
{
    nothrow:

    Exp op1;
    Exp op2;
    
    this (dstring txt, Exp op1, Exp op2)
    {
        super (txt);
        this.op1 = op1;
        this.op2 = op2;
    }

    mixin Acceptors!();
}
