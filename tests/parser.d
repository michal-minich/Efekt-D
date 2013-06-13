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

    void testStr(dstring code, dstring expected, EvalStrategy es = EvalStrategy.strict)
    {
        check(!rc.remarks.length, "Previous test has unverified remarks");

        sp.clear();
        auto asis = p.parse(code, es);
        if (asis)
        {
            asis[0].accept(ap);
            check(sp.str == expected, "Parsed other than expected value");
        }
        else
        {
            check(asis is null, "Expected nothing");
        }
    }


    void verifyRemarks(dstring[] names ...) { tests.utils.verifyRemarks(p.hasError, rc, names); }
    void ignoreRemarks() { rc.clear(); }


    testStr("", null);
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
    verifyRemarks("opWithoutOperands");

    testStr("1+", "1 + <missing>");
    verifyRemarks("expExpectedAfterOp");

    testStr("var", null);
    verifyRemarks("varNameIsMissing");

    testStr("var x", "var x");
    verifyRemarks("varEqualsIsMissing");

    testStr("var x =", "var x");
    verifyRemarks("varValueIsMissing");

    testStr("var x = var x = 1", "var x");
    verifyRemarks("varValueIsNotExp");

    testStr("9223372036854775807", "9223372036854775807");
    testStr("9223372036854775808", "9223372036854775807", EvalStrategy.lax);
    verifyRemarks("numberNotInRange");

    testStr("9223372036854775808", "<error>");
    verifyRemarks("numberNotInRange");

    testStr("1", "1");
}