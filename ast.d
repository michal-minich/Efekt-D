module ast;

import std.conv, std.bigint;
import common, printer, interpreter;

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


final class Int : Exp
{
    nothrow:
    mixin Acceptors!();

    dstring asString;
    long asLong;

    
    this (long asLong) { this.asLong = asLong; }


    @trusted this (dstring asString)
    {
        this.asString = asString;

        try
        {
           auto bi = BigInt(asString.to!string());
           if (bi > long.max)
                errp.error("Number must be in range 0 - 9'223 372 036'854 775 807");
            asLong = bi.toLong();
        }
        catch (Exception ex)
        {
            assert (false, ex.toString());
        }
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
