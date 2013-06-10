module ast;

import printer;

@safe nothrow:


interface AsiVisitor (R)
{
    nothrow:

    R visit (Var);
    R visit (Missing);
    R visit (Err);
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


abstract class Stm : Asi
{
    nothrow:
    this (dstring txt) { super (txt); }
}


abstract class Exp : Asi
{
    nothrow:
    this (dstring txt) { super (txt); }
}


class Var : Stm
{
    nothrow:
    mixin Acceptors!();
    Exp value;
    this (dstring name, Exp value) { super (name); this.value = value; }
}


class Missing : Exp
{
    nothrow:
    mixin Acceptors!();
    this () { super (null); }
}


class Err : Exp
{
    nothrow:
    mixin Acceptors!();
    Asi asi;
    this (Asi asi) { super (null); this.asi = asi; }
}


final class Int : Exp
{
    nothrow:
    mixin Acceptors!();
    this (dstring txt) { super (txt); }
}


final class OpApply : Exp
{
    nothrow:

    mixin Acceptors!();

    Exp op1;
    Exp op2;
    
    this (dstring txt, Exp op1, Exp op2)
    {
        super (txt);
        this.op1 = op1;
        this.op2 = op2;
    }
}
