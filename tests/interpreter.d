module tests.interpreter;

import tests.utils, remarks, exceptions, interpreter;

@safe nothrow:




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
    dstring code2;

    void evalTest(dstring code, dstring expected, EvalStrategy es = EvalStrategy.throwing)
    {
        code2 = code;
        check(!rc.remarks.length, "Previous test has unverified remarks");
        check(!ec.exceptions.length, "Previous test has unverified exceptions");

        sp.clear();
        auto asis = p.parse(code, es);

        if (p.hasError && EvalStrategy.throwing)
            check(expected is null, "Nothing expected when parser has error and es == throwing");

        auto res = interpreter.run(asis, es);
        if (res)
        {
            res.accept(ap);
            check(sp.str == expected, "Evaluated other than expected value.");
        }
        else
        {
            check(expected is null, "Expected nothing");
        }
    }


    void verifyRemarks(dstring[] names ...) { tests.utils.verifyRemarks(code2, p.hasError, rc, names); }
    void ignoreRemarks() { rc.clear(); }
    void verifyExceptions(dstring[] names ...) { tests.utils.verifyExceptions(code2, ec, names); }
    void ignoreExceptions() { ec.clear(); }


    evalTest("", null);
    evalTest(" \t", null);
    evalTest("1", "1");
    evalTest("1+2", "3");

    evalTest("+3", null);
    verifyRemarks("expExpectedBeforeOp");
    verifyExceptions("cannotEvalMissing");

    evalTest("+", null);
    verifyRemarks("opWithoutOperands");
    verifyExceptions("cannotEvalMissing");

    evalTest("3+", null);
    verifyRemarks("expExpectedAfterOp");
    verifyExceptions("cannotEvalMissing");


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