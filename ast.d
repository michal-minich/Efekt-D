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
    R visit (Assign);
    R visit (Int);
    R visit (OpApply);
}


mixin template Acceptors ()
{
    nothrow override void accept (AsiPrinter v) { v.visit(this); }
    override Asi accept (Interpreter v) { return v.visit(this); }
}


abstract class  Asi
{
    Asi accept (Interpreter);
    nothrow:
    void accept (AsiPrinter);
    @property asStm () { return cast(Stm)this; }
    @property asExp () { return cast(Stm)this; }
    @property asVar () { return cast(Var)this; }
    @property asMissing () { return cast(Missing)this; }
    @property asErr () { return cast(Err)this; }
    @property asIdent () { return cast(Ident)this; }
    @property asAssign () { return cast(Assign)this; }
    @property asInt () { return cast(Int)this; }
    @property asOpApply () { return cast(OpApply)this; }
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
    mixin Acceptors!();
    nothrow:
    Exp exp; // Ident | Assign
    this (Exp exp) { this.exp = exp; }
    @property dstring name ()
    {
        auto i = exp.asIdent;
        if (i)
            return i.name;
        auto a = exp.asAssign;
        if (a)
            return a.name;
        return null;
    }
}


class Missing : Exp
{
    mixin Acceptors!();
    nothrow:
}


class Err : Exp
{
    mixin Acceptors!();
    nothrow:
    Asi asi;
    this (Asi asi) { this.asi = asi; }
    //invariant () { assert(asi !is null); }
}


final class Ident : Exp
{
    mixin Acceptors!();
    nothrow:
    dstring name;
    this (dstring name) { this.name = name; }
}


class Assign : Exp
{
    mixin Acceptors!();
    nothrow:
    dstring name;
    Exp value;
    this (dstring name, Exp value) { this.name = name; this.value = value; }
}



final class Int : Exp
{
    mixin Acceptors!();
    nothrow:

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
    mixin Acceptors!();
    nothrow:

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
