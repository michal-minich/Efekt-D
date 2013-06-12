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
    Exp[dstring] vars;


    this (Thrower thrower) { this.thrower = thrower; }


    Asi run (Asi[] asis, EvalStrategy es)
    {
        if (!asis.length)
            return null;

        this.es = es;

        assert (asis.length == 1);

        return asis[0].accept(this);
    }


    Exp eval (Exp e)
    {
        return sureCast!Exp(e.accept(this));
    }


    Var visit (Var v)
    {
        auto val = v.value ? eval(v.value) : new Missing;
        vars[v.name] = val;
        return null;
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

    
    Exp visit (Ident i)
    {
        auto var = i.name in vars;
        if (var)
            return eval(*var);
        
        thrower.undefinedVariable(i.name);
        return null;
    }
    

    Int visit (Int i) { return i; }


    Exp visit (OpApply opa)
    {
        auto o1 = opa.op1;
        auto o2 = opa.op2;
        Exp firstGood;

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
        }
        else
        {
            Asi x = cast(Missing)opa.op1;
            if (x)
                o1 = new Int(0);
            else
            {
                x = cast(Err)opa.op1;
                if (x)
                    o1 = new Int(0);
                else
                    firstGood = opa.op1;
            }

            x = cast(Missing)opa.op2;
            if (x)
                o2 = new Int(0);
            else
            {
                x = cast(Err)opa.op2;
                if (x)
                    o2 = new Int(0);
                else if (!firstGood)
                    firstGood = opa.op2;
            }
        }

        auto opfn = opa.op in ops;
        if (opfn)
            return (*opfn)(es, thrower, eval(o1), eval(o2));
        
        final switch (es) with (EvalStrategy)
        {
            case throwing:
                thrower.opeatorIsUndefined (opa.op);
                return null;
            case strict:
                return new Err(opa);
            case lax:
                assert (firstGood);
                return firstGood;
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
        check(!rc.remarks.length, "Previous test has unverified remarks");
        check(!ec.exceptions.length, "Previous test has unverified exceptions");

        sp.clear();
        auto asis = p.parse(code, es);

        if (p.hasError && EvalStrategy.throwing)
            check(expected is null);

        auto res = interpreter.run(asis, es);
        if (res)
        {
            res.accept(ap);
            check(sp.str == expected);
        }
        else
        {
            check(expected is null);
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
    verifyRemarks("opWithoutOperands");
    verifyExceptions("cannotEvalErrorOrMissing");

    evalTest("3+", null);
    verifyRemarks("expExpectedAfterOp");
    verifyExceptions("cannotEvalErrorOrMissing");


    evalTest("+3", "<error <missing> + 3>", EvalStrategy.strict);
    verifyRemarks("expExpectedBeforeOp");

    evalTest("+", "<error <missing> + <missing>>", EvalStrategy.strict);
    verifyRemarks("opWithoutOperands");

    evalTest("3+", "<error 3 + <missing>>", EvalStrategy.strict);
    verifyRemarks("expExpectedAfterOp");


    evalTest("+3", "3", EvalStrategy.lax);
    verifyRemarks("expExpectedBeforeOp");

    evalTest("+", "0", EvalStrategy.lax);
    verifyRemarks("opWithoutOperands");

    evalTest("3+", "3", EvalStrategy.lax);
    verifyRemarks("expExpectedAfterOp");
    

    evalTest("9223372036854775808", "<error>", EvalStrategy.strict);
    verifyRemarks("numberNotInRange");

    evalTest("9223372036854775806 + 2", "9223372036854775807", EvalStrategy.lax);

    evalTest("9223372036854775806 + 2", null, EvalStrategy.throwing);
    verifyExceptions("integerOwerflow");

    evalTest("", null);
}