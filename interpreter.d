module interpreter;

import utils, common, ast, remarks;

@safe nothrow:


alias opFn = Exp function (EvalStrategy, Exp, Exp);

private opFn[dstring] ops;


static this ()
{
    ops = ["+"d : &plus];
}


@trusted Exp plus (EvalStrategy es, Exp op1, Exp op2)
{
    immutable o1 = sureCast!Int(op1).asLong;
    immutable o2 = sureCast!Int(op2).asLong;
    auto res = o1 + o2;
    asm { jo overflowed; }
    return new Int(res);
    overflowed:
    if (es == EvalStrategy.strict)
        return new Int(res);
    else
        return new Int(long.max);
}


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

            return ops[opa.op](es, opa.op1, opa.op2);
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

            return ops[opa.op](es, o1, o2);
        }
    }
}


unittest
{
    import common, printer, parser;

    auto rc = new RemarkCollector;
    remark = new Remarker(rc);
    auto sp = new StringPrinter;
    auto ap = new printer.AsiPrinter(sp);
    auto interpreter = new Interpreter;

    void evalTest(dstring code, dstring expected, EvalStrategy es = EvalStrategy.strict)
    {
        //assert (!rc.remarks.length, "Previous test has unverified remarks");
        rc.clear();
        sp.clear();
        auto asis = parse(code, es);
        auto res = interpreter.run(asis, es);
        if (res)
        {
            res.accept(ap);
            assert(sp.str == expected);
        }
        else
        {
            assert (expected == "");
        }
    }


    void verifyRemarks(dstring[] names ...)
    {
        assert(rc.remarks.length == names.length);
        foreach (ix, n; names)
            assert (rc.remarks[ix].name == n);

        rc.clear();
        assert(!rc.remarks.length);
    }


    evalTest("", "");
    evalTest(" \t", "");
    evalTest("1", "1");
    evalTest("1+2", "3");

    evalTest("+3", "<error <missing> + 3>");
    verifyRemarks("expExpectedBeforeOp");

    evalTest("+", "<error <missing> + <missing>>");
    //verifyRemarks("opWithoutOperands");

    evalTest("3+", "<error 3 + <missing>>");
    //verifyRemarks("expExpecteAfterOp");


    evalTest("+3", "3", EvalStrategy.lax);
    verifyRemarks("expExpectedBeforeOp");

    evalTest("+", "0", EvalStrategy.lax);
    //verifyRemarks("opWithoutOperands");

    evalTest("3+", "3", EvalStrategy.lax);
    //verifyRemarks("expExpecteAfterOp");


    evalTest("9223372036854775808", "<error>");
    verifyRemarks("numberNotInRange");

    evalTest("9223372036854775808", "9223372036854775807", EvalStrategy.lax);
    verifyRemarks("numberNotInRange");
}