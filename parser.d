module parser;

import std.conv, std.bigint;
import common, ast;

@safe nothrow:


string next (string end)
{
    return "
    ++codeIx;
    if (codeIx == code.length) goto " ~ end ~ ";
    ch = code[codeIx];";
}


@trusted private Exp getIntOrErrFromString(dstring s, EvalStrategy es)
{
    try
    {
        auto bi = BigInt(s.to!string());
        if (bi > long.max)
        {
            errp.error("Number must be in range 0 - 9'223 372 036'854 775 807");
            return es == EvalStrategy.strict
                ? new Err(null)
                : new Int(s, bi.toLong());
        }
        else
        {
            return new Int(s, bi.toLong());
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
            asis[asiIx] = i;
            ++asiIx;
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
                errp.error("Expression expected before operator, not statement");
                op1 = new Err(asis[opaIx]);
            }
        }
        else
        {
            opaIx = 0;
            op1 = new Missing;
            errp.error("Expression expected before operator");
            ++asiIx;
        }

        asis[opaIx] = new OpApply(code[codeIx .. codeIx + 1], op1, new Missing);
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

    return asis[0 .. asiIx];
}


unittest
{
    import common, printer;

    errp = new ErrorPrinter(new StdErrPrinter);
    auto sp = new StringPrinter;
    auto ap = new printer.AsiPrinter(sp);

    void testStr(dstring code, dstring asi, EvalStrategy es = EvalStrategy.strict)
    {
        sp.reset();
        parse(code, es)[0].accept(ap);
        //stdp.print(code);
        //stdp.print(" | ");
        //stdp.println(asi);
        assert(sp.str == asi);
    }

    assert(parse("", EvalStrategy.strict).length == 0);
    testStr("1", "1");
    testStr("123", "123");
    testStr("  123", "123");
    testStr("123  ", "123");
    testStr("  123  ", "123");
    testStr("\t1", "1");
    testStr("1\t", "1");
    testStr("\t1\t", "1");

    testStr("+1", "<missing> + 1");
    testStr("+", "<missing> + <missing>");
    testStr("1+", "1 + <missing>");

    testStr("9223372036854775807", "9223372036854775807");
    testStr("9223372036854775808", "9223372036854775807", EvalStrategy.lax);
    testStr("9223372036854775808", "<error>");
}