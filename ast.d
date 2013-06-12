module ast;

import common, printer, interpreter;

@safe nothrow:


interface AsiVisitor (R)
{
    nothrow:

    R visit (Var);
    R visit (Missing);
    R visit (Err);
    R visit (Ident);
    R visit (Int);
    R visit (OpApply);
}


mixin template Acceptors ()
{
    override void accept (AsiPrinter v) { v.visit(this); }
    override Asi accept (Interpreter v) { return v.visit(this); }
}


abstract class  Asi
{
    nothrow:
    void accept (AsiPrinter);
    Asi accept (Interpreter);
}


abstract class Stm : Asi
{
    nothrow:
}


abstract class Exp : Asi
{
    nothrow:
}


class Var : Stm
{
    nothrow:
    mixin Acceptors!();
    dstring name;
    Exp value;
    this (dstring name, Exp value) { this.name = name; this.value = value; }
}


class Missing : Exp
{
    nothrow:
    mixin Acceptors!();
}


class Err : Exp
{
    nothrow:
    mixin Acceptors!();
    Asi asi;
    this (Asi asi) { this.asi = asi; }
}


final class Ident : Exp
{
    nothrow:
    mixin Acceptors!();
    dstring name;
    this (dstring name) { this.name = name; }
}


final class Int : Exp
{
    nothrow:
    mixin Acceptors!();

    dstring asString;
    long asLong;

    
    this (long asLong) { this.asLong = asLong; }


    this (dstring asString, long asLong)
    {
        this.asString = asString;
        this.asLong = asLong;
    }
}


final class OpApply : Exp
{
    nothrow:

    mixin Acceptors!();

    dstring op;
    Exp op1;
    Exp op2;
    
    this (dstring op, Exp op1, Exp op2)
    {
        this.op = op;
        this.op1 = op1;
        this.op2 = op2;
    }
}
