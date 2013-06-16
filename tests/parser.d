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
    dstring code2;

    void testStr(dstring code, dstring expected, EvalStrategy es = EvalStrategy.strict)
    {
        code2 = code;
        check(!rc.remarks.length, "Previous test has unverified remarks");

        sp.clear();
        auto asis = p.parse(code, es);
        if (asis)
        {
            asis[0].accept(ap);
            check(sp.str == expected, "Parsed other than expected value '"
                  ~ code ~ "' -> '"~ sp.str ~ "' != '" ~ expected ~ "'");
        }
        else
        {
            check(asis is null, "Expected nothing");
        }
    }


    void verifyRemarks(dstring[] names ...) { tests.utils.verifyRemarks(code2, p.hasError, rc, names); }
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

    testStr("var", "var <missing>");
    verifyRemarks("varNameIsMissing");

    testStr("var x", "var x");
    verifyRemarks();
    

    testStr("var x 1", "var x = 1");
    verifyRemarks("varEqualsIsMissing");

    testStr("var x =", "var x = <missing>");
    verifyRemarks("varValueIsMissing");

    testStr("var x = var x = 1", "var x = <error var x = 1>");
    verifyRemarks("varValueIsNotExp");

    testStr("var 1", "var <missing> = 1");
    verifyRemarks("expOrStmInsteadOfVarNameFound");

    testStr("var = 1", "var <missing> = 1");
    verifyRemarks("varNameIsMissing");

    /*testStr("var var", "var <missing>\nvar <missing>");
    verifyRemarks();

    testStr("var var x", "var <missing>\nvar x");
    verifyRemarks();

    testStr("var var x = 1", "<var <missing>\nvar x = 1");
    verifyRemarks();

    testStr("var x var x", "var x\nvar x");
    verifyRemarks();

    testStr("var x x", "var x = x");
    verifyRemarks();

    testStr("var x = x", "var x = x");
    verifyRemarks();

    testStr("var x = x + 1", "var x = x +  1");
    verifyRemarks();*/

    testStr("var x = 1 + 2", "<error var x = 1> + 2");
    verifyRemarks("expExpectedBeforeOpButStmFound");

    testStr("2 + var x = 1", "2 + <error var x = 1>");
    verifyRemarks("expExpectedAfterOpButStmFound");

    testStr("var x = 1 + var x = 2", "<error var x = 1> + <error var x = 2>");
    verifyRemarks("opBetweenStatements");


    testStr("9223372036854775807", "9223372036854775807");
    testStr("9223372036854775808", "9223372036854775807", EvalStrategy.lax);
    verifyRemarks("numberNotInRange");

    testStr("9223372036854775808", "<error>");
    verifyRemarks("numberNotInRange");

    testStr("1", "1");
}