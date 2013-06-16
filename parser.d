module parser;

import std.conv, std.bigint;
import utils, common, ast, remarks;

@safe nothrow:


private enum ParseContext
{
    none,
    var,
    assign,
    op,
}


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
            asi = parseAsi(ParseContext.none, code2, asi, es, replace);
            if (!asi)
                break;
            if (replace && asis.length)
                asis[$ - 1] = asi;
            else
                asis ~= asi;
        }

        return asis;
    }


    private Asi parseAsi (ParseContext ctx, ref dstring code, Asi prevAsi, 
                         EvalStrategy es, out bool replace)
    {
        replace = false;

        skipWhite(code);

        if (!code.length)
            return null;

        if (matchIdent(code, "var"))
        {
            bool _;
            Asi res;

            skipWhite(code);
            if (matchOp(code, "="))
            {
                remark.parser.varNameIsMissing();
                auto val = parseAsi(ParseContext.var, code, null, es, _);
                auto exp = cast(Exp)val;
                if (!val)
                {
                    exp = new Missing;
                }
                else if (!exp)
                {
                    remark.parser.varValueIsNotExp();
                    exp = new Err(val);
                }
                return new Var(new Assign ("<missing>", exp));
            }
                
            res = parseAsi(ParseContext.var, code, null, es, _);

            auto ass = cast(Assign)res;
            if (ass)
                return new Var(ass);

            auto ident = cast(Ident)res;
            if (ident)
                return new Var(ident);
        
            auto exp = cast(Exp)res;
            if (exp)
            {
                remark.parser.expOrStmInsteadOfVarNameFound();
                return new Var(new Assign("<missing>", exp));
            }

            if (res)
            {
                remark.parser.expOrStmInsteadOfVarNameFound();
                return new Var(new Assign("<missing>", new Err(res)));
            }

            remark.parser.varNameIsMissing();
            return new Var(new Ident("<missing>"));
        }
        else if (auto m = match(code, &isIdent))
        {
            auto ident = new Ident(m);
            skipWhite(code);
            auto mEq = matchOp(code, "=");

            if (ctx != ParseContext.var && !mEq)
                return ident;

            bool _;
            auto val = parseAsi(ParseContext.assign, code, null, es, _);
            if (!val)
            {
                if (!mEq)
                    return ident;

                remark.parser.varValueIsMissing();
                return new Assign(ident.name, new Missing);
            }

            if (!mEq)
                remark.parser.varEqualsIsMissing();

            auto exp = cast(Exp)val;
            if (exp)
                return new Assign(ident.name, exp);

            remark.parser.varValueIsNotExp();
            return new Assign(ident.name, new Err(val));
        }
        else if (auto m = match(code, &isInt))
        {
            return getIntOrErrFromString(m, es, hasError);
        }
        else if (auto m = match(code, &isOp))
        {       
            bool _;
            auto op1 = prevAsi;
            auto op2 = parseAsi(ParseContext.op, code, null, es, _);

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



dstring matchIdent(ref dstring code, const dstring s)
{
    if (code.length < s.length)
        return null;

    if (code[0 .. s.length] != s)
        return null;

    auto m = code[0 .. s.length];

    code = code[s.length .. $];

    if (!code.length || (code.length && !code[0].isIdent()))
        return m;

    return null;
}



dstring matchOp(ref dstring code, const dstring s)
{
    if (code.length < s.length)
        return null;

    if (code[0 .. s.length] != s)
        return null;

    auto m = code[0 .. s.length];

    code = code[s.length .. $];

    if (!code.length || (code.length && !code[0].isOp()))
        return m;

    return null;
}