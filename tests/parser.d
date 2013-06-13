module tests.parser;

import tests.utils, remarks, parser;

@safe nothrow:


unittest
{
    import common, printer;

    auto rc = new RemarkCollector;
    remark = new Remarker(rc);
    auto sp = new StringPrinter;
    auto ap = new printer.AsiPrinter(sp);
    auto p = new Parser;

    void testStr(dstring code, dstring asi, EvalStrategy es = EvalStrategy.strict)
    {
        check(!rc.remarks.length, "Previous test has unverified remarks");

        sp.clear();
        p.parse(code, es)[0].accept(ap);
        //stdp.print(code);
        //stdp.print(" | ");
        //stdp.println(asi);
        check(sp.str == asi);
    }


    void verifyRemarks(dstring[] names ...) { tests.utils.verifyRemarks(p.hasError, rc, names); }
    void ignoreRemarks() { rc.clear(); }


    assert(p.parse("", EvalStrategy.strict).length == 0);
    testStr("1", "1");
    testStr("123", "123");
    testStr("  123", "123");
    testStr("123  ", "123");
    testStr("  123  ", "123");
    testStr("\t1", "1");
    testStr("1\t", "1");
    testStr("\t1\t", "1");


    testStr("+1", "<missing> + 1");
    verifyRemarks("expExpectedBeforeOp");

    testStr("+", "<missing> + <missing>");
    //verifyRemarks("opWithoutOperands");
    ignoreRemarks();

    testStr("1+", "1 + <missing>");
    //verifyRemarks("expExpecteAfterOp");
    ignoreRemarks();


    testStr("9223372036854775807", "9223372036854775807");
    testStr("9223372036854775808", "9223372036854775807", EvalStrategy.lax);
    verifyRemarks("numberNotInRange");

    testStr("9223372036854775808", "<error>");
    verifyRemarks("numberNotInRange");

    testStr("1", "1");
}