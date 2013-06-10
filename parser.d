module parser;

import ast;

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

    next:

    while (ch == ' ' || ch == '\t')
        mixin (next("end"));

    if (ch =='+')
    {
        Exp op1;
        if (asiIx)
        {
            op1 = cast(Exp)asis[asiIx - 1];
            if (!op1)
                assert(false, "expression expected before operator, not statement");
        }
        else
            assert(false, "expression expected before operator");

        mixin (next("end"));

        asis[asiIx - 1] = new OpApply(code[codeIx - 1 .. codeIx], op1, null);
    }

    if (ch >= '0' && ch <= '9')
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

    if (codeIx != code.length)
        goto next;

    end:

    return asis[0 .. asiIx];
}


unittest
{
    assert(parse("").length == 0);
    assert(parse("1")[0].text == "1");
    assert(parse("123")[0].text == "123");
    assert(parse("  123")[0].text == "123");
    assert(parse("123  ")[0].text == "123");
    assert(parse("  123  ")[0].text == "123");
    assert(parse("\t1")[0].text == "1");
    assert(parse("1\t")[0].text == "1");
    assert(parse("\t1\t")[0].text == "1");
}