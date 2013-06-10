module parser;

import common, ast;

@safe nothrow:


string next (string end)
{
    return "
    ++codeIx;
    if (codeIx == code.length) goto " ~ end ~ ";
    ch = code[codeIx];";
}


Asi[] parse(dstring code)
{
    if (!code.length)
        return null;

    enum maxAsis = 1000;
    size_t codeIx;
    size_t startIx;
    size_t asiIx;
    dchar ch = code[0];
    auto asis = new Asi[maxAsis];


    nothrow void parseExp()
    {
        startIx = codeIx;

        mixin (next("intEnd"));

        while (ch >= '0' && ch <= '9')
            mixin (next("intEnd"));

        intEnd:

        auto i = new Int(code[startIx .. codeIx]);

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
        parseExp();
    }

    if (codeIx != code.length)
        goto next;

    end:

    return asis[0 .. asiIx];
}


unittest
{
    import common, printer;

    auto stdp = new StdOutPrinter;
    errp = new ErrorPrinter(new StdErrPrinter);
    auto sp = new StringPrinter;
    auto ap = new printer.AsiPrinter(sp);

    void testStr(dstring code, dstring asi)
    {
        sp.reset();
        parse(code)[0].accept(ap);
        assert(sp.str == asi);
        
        //stdp.print(code);
        //stdp.print(" | ");
        //stdp.println(asi);
    }

    assert(parse("").length == 0);
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
    testStr("9223372036854775808", "9223372036854775807");
    
    stdp.println("All Tests Succeeded");
}