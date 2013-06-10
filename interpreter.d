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


enum EvalStrategy { strict, lax }


final class Interpreter : AsiVisitor!Asi
{
    nothrow:

    private EvalStrategy es;


    Asi run (Asi[] asis, EvalStrategy es)
    {
        if (!asis.length)
            return null;

        this.es = es;

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
        if (es == EvalStrategy.strict)
        {
            Asi x = cast(Missing)opa.op1;
            if (x)
                return new Err(opa);

            x = cast(Err)opa.op1;
            if (x)
                return new Err(opa);

            x = cast(Missing)opa.op2;
            if (x)
                return new Err(opa);

            x = cast(Err)opa.op2;
            if (x)
                return new Err(opa);

            return ops[opa.op](opa.op1, opa.op2);
        }
        else
        {
            auto o1 = opa.op1;
            auto o2 = opa.op2;
            Asi x = cast(Missing)opa.op1;
            if (x)
                o1 = new Int(0);
            else
            {
                x = cast(Err)opa.op1;
                if (x)
                    o1 = new Int(0);
            }

            x = cast(Missing)opa.op2;
            if (x)
                o2 = new Int(0);
            else
            {
                x = cast(Err)opa.op2;
                if (x)
                    o2 = new Int(0);
            }

            return ops[opa.op](o1, o2);
        }
    }
}