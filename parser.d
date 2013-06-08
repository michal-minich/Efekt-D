module parser;


import ast;


@safe nothrow:


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
    {
        ++codeIx;
        if (codeIx == code.length) goto end;
        ch = code[codeIx];
    }

    if (ch >= '0' && ch <= '9')
    {
        startIx = codeIx;

        ++codeIx;
        if (codeIx == code.length) goto intEnd;
        ch = code[codeIx];

        while (ch >= '0' && ch <= '9')
        {
            ++codeIx;
            if (codeIx == code.length) goto intEnd;
            ch = code[codeIx];
        }

        intEnd:

        asis[asiIx] = new Int(code[startIx .. codeIx]);
        ++asiIx;
    }

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