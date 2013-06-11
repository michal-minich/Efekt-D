module parser;

import std.conv, std.bigint;
import common, ast, remarks;

@safe nothrow:


string next (string end)
{
    return "
    ++codeIx;
    if (codeIx == code.length) goto " ~ end ~ ";
    ch = code[codeIx];";
}

final class Parser
{
nothrow:

bool hasError;


T newAsi (T : Asi, Args...) (Args args)
{
    return new T(args);
}


@trusted private Exp getIntOrErrFromString(dstring s, EvalStrategy es)
{
    try
    {
        auto bi = BigInt(s.to!string());
        if (bi > long.max)
        {
            remark.parser.numberNotInRange();
            hasError = true;
            return es == EvalStrategy.lax
                ? newAsi!Int(s, bi.toLong())
                : newAsi!Err(null);
        }
        else
        {
            return newAsi!Int(s, bi.toLong());
        }
    }
    catch (Exception ex)
    {
        assert (false, ex.toString());
    }
}


Asi[] parse(dstring code, EvalStrategy es)
{
    if (!code.length)
        return null;

    hasError = false;
    enum maxAsis = 1000;
    size_t codeIx;
    size_t startIx;
    size_t asiIx;
    dchar ch = code[0];
    auto asis = new Asi[maxAsis];


    nothrow void parseInt()
    {
        startIx = codeIx;

        mixin (next("intEnd"));

        while (ch >= '0' && ch <= '9')
            mixin (next("intEnd"));

        intEnd:

        auto i = getIntOrErrFromString(code[startIx .. codeIx], es);

        OpApply opApply;
        if (asiIx)
            opApply = cast(OpApply)asis[asiIx - 1];

        if (opApply)
            opApply.op2 = i;
        else
        {
            asis[asiIx++] = i;
        }
    }


    nothrow void parseOp()
    {
        Exp op1;
        size_t opaIx;
        if (asiIx)
        {
            opaIx = asiIx - 1;
            op1 = cast(Exp)asis[opaIx];
            if (!op1)
            {
                remark.parser.expExpectedBeforeOpButStmFound();
                op1 = newAsi!Err(asis[opaIx]);
            }
        }
        else
        {
            opaIx = 0;
            op1 = newAsi!Missing();
            remark.parser.expExpectedBeforeOp();
            ++asiIx;
        }

        asis[opaIx] = newAsi!OpApply(code[codeIx .. codeIx + 1], op1, newAsi!Missing());
    }

    next:

    while (ch == ' ' || ch == '\t')
        mixin (next("end"));

    if (ch =='+')
    {
        parseOp();
        mixin (next("end"));
    }

    if (ch >= '0' && ch <= '9')
    {
        parseInt();
    }

    if (codeIx != code.length)
        goto next;

    end:

    auto opa = cast(OpApply)asis[0];
    if (opa)
    {
        auto o1 = cast(Missing)opa.op1;
        if (o1)
        {
            hasError = true;
        }

        auto o2 = cast(Missing)opa.op1;
        if (o2)
        {
            hasError = true;
        }
    }

    return asis[0 .. asiIx];
}
}

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
        assert (!rc.remarks.length, "Previous test has unverified remarks");

        sp.clear();
        p.parse(code, es)[0].accept(ap);
        //stdp.print(code);
        //stdp.print(" | ");
        //stdp.println(asi);
        assert(sp.str == asi);
    }


    void verifyRemarks(dstring[] names ...) { common.verifyRemarks(p.hasError, rc, names); }
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