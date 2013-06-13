module parser;

import std.conv, std.bigint;
import utils, common, ast, remarks;

@safe nothrow:


final class Parser
{
    nothrow:

    bool hasError;

    Asi[] parse (dstring code, EvalStrategy es)
    {
        if (!code.length)
            return [];

        auto code2 = code;

        hasError = false;

        Asi asi;
        Asi[] asis;
        while (true)
        {
            bool replace;
            asi = parseAsi(code2, asi, es, replace);
            if (!asi)
                break;
            if (replace && asis.length)
                asis[$ - 1] = asi;
            else
                asis ~= asi;
        }

        return asis;
    }


    private Asi parseAsi (ref dstring code, Asi prevAsi, EvalStrategy es, out bool replace)
    {
        replace = false;

        skipWhite(code);

        if (!code.length)
            return null;

        if (matchWithWhite(code, "var"))
        {
            bool _;

            auto name = parseAsi(code, null, es, _);
            auto ident = cast(Ident)name;

            if (!name)
            {
                remark.parser.missingVarName();
                return null;
            }
            else if (!ident)
            {
                remark.parser.expOrStmInsteadOfVarNameFound();
                return new Err(name);
            }
            else
            {
                skipWhite(code);
                
                if (!matchWithWhite(code, "="))
                {
                    remark.parser.expectedEquals();
                }
                
                auto val = parseAsi(code, null, es, _);
                auto exp = cast(Exp)val;
                if (!val)
                {
                    val = new Missing;
                }
                else if (!exp)
                {
                    remark.parser.varValueIsNotStm();
                    val = new Err(val);
                }

                return new Var(ident.name, exp);
            }
        }
        else if (auto m = match(code, &isIdent))
        {
            return new Ident(m);
        }
        else if (auto m = match(code, &isInt))
        {
            return getIntOrErrFromString(m, es, hasError);
        }
        else if (auto m = match(code, &isOp))
        {       
            bool _;
            auto op1 = prevAsi;
            auto op2 = parseAsi(code, null, es, _);

            if (!prevAsi && !op2)
            {
                remark.parser.opWithoutOperands();
                op1 = new Missing;
                op2 = new Missing;
            }
            else if (!prevAsi)
            {
                remark.parser.expExpectedBeforeOp();
                op1 = new Missing;
            }
            else if (!op2)
            {
                remark.parser.expExpectedAfterOp();
                op2 = new Missing;
            }

            auto stm1 = cast(Stm)prevAsi;
            auto stm2 = cast(Stm)op2;

            if (stm1 && stm2)
            {
                remark.parser.opBetweenStatements();
                op1 = new Err(stm1);
                op2 = new Err(stm2);
            }
            else if (stm1)
            {
                remark.parser.expExpectedBeforeOpButStmFound();
                op1 = new Err(stm1);
            }
            else if (stm2)
            {
                remark.parser.expExpectedAfterOpButStmFound();
                op2 = new Err(stm2);
            }

            replace = true;
            return new OpApply(m, sureCast!Exp(op1), sureCast!Exp(op2));
        }

        remark.parser.unexpectedChar();
        return null;
    }
}


private:


void skipWhite (ref dstring code)
{
    while (true)
    {
        if (!code.length)
            return;
        if (code[0].isWhite())
            code = code[1 .. $];
        else
            break;
    }
}


@trusted Exp getIntOrErrFromString (dstring s, EvalStrategy es, out bool hasError)
{
    try
    {
        auto bi = BigInt(s.toString());
        if (bi > long.max)
        {
            remark.parser.numberNotInRange();
            hasError = true;
            return es == EvalStrategy.lax
                ? new Int(s, bi.toLong())
                : new Err(null);
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

bool isWhite (const dchar ch) { return ch == ' ' || ch == '\t'; }
bool isInt (const dchar ch) { return ch >= '0' && ch <= '9'; }
bool isIdent (const dchar ch) { return ch >= 'a' && ch <= 'z'; }

bool isOp (const dchar ch)
{ 
    return ch == '+' || ch == '-' || ch == '*' || ch == '\\' || ch == '%';
}




dstring match(ref dstring code, bool function (const dchar) @safe nothrow isMatch)
{
    size_t i;
    do
    {
        if (!isMatch(code[i]))
        {
            if (i > 0)
                break;
            else
                return null;
        }
        ++i;
    } while (code.length > i);

    auto m = code[0 .. i];
    code = code[i .. $];
    return m;
}


dstring match(ref dstring code, const dstring s)
{
    if (code.length < s.length)
        return null;

    if (code[0 .. s.length] != s)
        return null;

    auto m = code[0 .. s.length];
    code = code[s.length .. $];
    return m;
}



dstring matchWithWhite(ref dstring code, const dstring s)
{
    if (code.length < s.length)
        return null;

    if (code[0 .. s.length] != s)
        return null;

    auto m = code[0 .. s.length];

    code = code[s.length .. $];

    if (!code.length || (code.length && code[0].isWhite()))
        return m;

    return null;
}