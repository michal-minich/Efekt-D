module interpreter;

import utils, ast;

@safe nothrow:


alias opFn = Exp function (Exp, Exp);

private opFn[dstring] ops;


static this ()
{
    ops = ["+"d : &plus];
}


Exp plus (Exp op1, Exp op2)
{
    immutable o1 = sureCast!Int(op1).asLong;
    immutable o2 = sureCast!Int(op2).asLong;
    return new Int(o1 + o2);
}


final class Interpreter : AsiVisitor!Asi
{
    nothrow:

    Asi run (Asi[] asis)
    {
        if (!asis.length)
            return null;

        assert (asis.length == 1);

        return asis[0].accept(this);
    }



    Var visit (Var v)
    {
        assert (false);
    }


    Missing visit (Missing m)
    {
        return m;
    }


    Err visit (Err er)
    {
        return er;
    }


    Int visit (Int i) { return i; }


    Exp visit (OpApply opa)
    {
        return ops[opa.op](opa.op1, opa.op2);
    }
}