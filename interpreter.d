module interpreter;

import utils, common, ast, remarks, exceptions;

@safe nothrow:


alias opFn = Exp function (EvalStrategy, Thrower, Exp, Exp);

private opFn[dstring] ops;


static this ()
{
    ops = ["+"d : &plus];
}


@trusted Exp plus (EvalStrategy es, Thrower th, Exp op1, Exp op2)
{
    immutable o1 = sureCast!Int(op1).asLong;
    immutable o2 = sureCast!Int(op2).asLong;
    auto res = o1 + o2;
    asm { jo overflowed; }
    return new Int(res);
    overflowed:
    if (es == EvalStrategy.throwing)
    {
        th.integerOwerflow();
        return null;
    }
    else if (es == EvalStrategy.strict)
        return new Int(res);
    else
        return new Int(long.max);
}


final class Interpreter : AsiVisitor!Asi
{
    nothrow:

    private EvalStrategy es;
    private Thrower thrower;


    this (Thrower thrower) { this.thrower = thrower; }


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
        if (es == EvalStrategy.throwing)
        {
            thrower.cannotEvalErrorOrMissing();
            return null;
        }

        return m;
    }


    Err visit (Err er)
    {
        if (es == EvalStrategy.throwing)
        {
            thrower.cannotEvalErrorOrMissing();
            return null;
        }

        return er;
    }


    Int visit (Int i) { return i; }


    Exp visit (OpApply opa)
    {
        if (es == EvalStrategy.throwing)
        {
            Asi x = cast(Missing)opa.op1;
            if (!x)
                x = cast(Missing)opa.op2;
            if (x)
            {
                thrower.cannotEvalErrorOrMissing();
                return null;
            }

            x = cast(Err)opa.op1;
            if (!x)
                x = cast(Err)opa.op2;
            if (x)
            {
                thrower.cannotEvalErrorOrMissing();
                return null;
            }

            else
                return ops[opa.op](es, thrower, opa.op1, opa.op2);
        }
        else if (es == EvalStrategy.strict)
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

            return ops[opa.op](es, thrower, opa.op1, opa.op2);
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

            return ops[opa.op](es, thrower, o1, o2);
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
    auto ec = new ExceptionCollector;
    auto interpreter = new Interpreter(new Thrower(ec));
    auto p = new Parser;

    void evalTest(dstring code, dstring expected, EvalStrategy es = EvalStrategy.throwing)
    {
        assert (!rc.remarks.length, "Previous test has unverified remarks");
        assert (!ec.exceptions.length, "Previous test has unverified exceptions");

        sp.clear();
        auto asis = p.parse(code, es);

        if (p.hasError && EvalStrategy.throwing)
            assert (expected is null);

        auto res = interpreter.run(asis, es);
        if (res)
        {
            res.accept(ap);
            assert(sp.str == expected);
        }
        else
        {
            assert (expected is null);
        }
    }


    void verifyRemarks(dstring[] names ...) { common.verifyRemarks(p.hasError, rc, names); }
    void ignoreRemarks() { rc.clear(); }
    void verifyExceptions(dstring[] names ...) { common.verifyExceptions(ec, names); }
    void ignoreExceptions() { ec.clear(); }


    evalTest("", null);
    evalTest(" \t", null);
    evalTest("1", "1");
    evalTest("1+2", "3");

    evalTest("+3", null);
    verifyRemarks("expExpectedBeforeOp");
    verifyExceptions("cannotEvalErrorOrMissing");

    evalTest("+", null);
    //verifyRemarks("opWithoutOperands");
    ignoreRemarks();
    verifyExceptions("cannotEvalErrorOrMissing");

    evalTest("3+", null);
    //verifyRemarks("expExpecteAfterOp");
    ignoreRemarks();
    verifyExceptions("cannotEvalErrorOrMissing");


    evalTest("+3", "<error <missing> + 3>", EvalStrategy.strict);
    verifyRemarks("expExpectedBeforeOp");

    evalTest("+", "<error <missing> + <missing>>", EvalStrategy.strict);
    //verifyRemarks("opWithoutOperands");
    ignoreRemarks();

    evalTest("3+", "<error 3 + <missing>>", EvalStrategy.strict);
    //verifyRemarks("expExpecteAfterOp");
    ignoreRemarks();


    evalTest("+3", "3", EvalStrategy.lax);
    verifyRemarks("expExpectedBeforeOp");

    evalTest("+", "0", EvalStrategy.lax);
    //verifyRemarks("opWithoutOperands");
    ignoreRemarks();

    evalTest("3+", "3", EvalStrategy.lax);
    //verifyRemarks("expExpecteAfterOp");
    ignoreRemarks();
    

    evalTest("9223372036854775808", "<error>", EvalStrategy.strict);
    verifyRemarks("numberNotInRange");

    evalTest("9223372036854775806 + 2", "9223372036854775807", EvalStrategy.lax);

    evalTest("9223372036854775806 + 2", null, EvalStrategy.throwing);
    verifyExceptions("integerOwerflow");

    evalTest("", null);
}