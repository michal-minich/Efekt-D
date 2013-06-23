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
    bool wasNewline;


    Asi[] parse (dstring code, EvalStrategy es)
    {
        if (!code.length)
            return null;

        auto code2 = code;

        hasError = false;

        Asi asi;
        Asi[] asis;
        while (true)
        {
            asi = parseAsi(ParseContext.none, code2, asi, es, false);
            if (asi)
                asis ~= asi;
            else
                break;
        }

        return asis;
    }




    private Asi parseAsi (ParseContext ctx, ref dstring code, Asi prevAsi, 
                             EvalStrategy es, bool onSameLineOnly)
    {
        auto asi = parseOneAsi (ctx, code, prevAsi, es, onSameLineOnly);
        if (asi && code.length)
        {
            skipWhite(code);
            if (code.length)
                if (auto m = match(code, &isOp))
                    return parseOpApply(ctx, code, asi, es, onSameLineOnly, m);
        }
        return asi;
    }




    private Asi parseOneAsi (ParseContext ctx, ref dstring code, Asi prevAsi, 
                             EvalStrategy es, bool onSameLineOnly)
    {
        again:

        skipWhite(code);

        if (!code.length)
        {
            return null;
        }
        else if (auto m = matchIdent(code, "var"))
        {
            return parseVar(ctx, code, prevAsi, es, onSameLineOnly, m);
        }
        else if (auto m = match(code, &isIdent))
        {
            return parseIdentOrAssign(ctx, code, prevAsi, es, onSameLineOnly, m);
        }
        else if (auto m = match(code, &isInt))
        {
            return getIntOrErrFromString(m, es, hasError);
        }
        else if (auto m = match(code, &isOp))
        {
            return parseOpApply(ctx, code, prevAsi, es, onSameLineOnly, m);
        }

        if (code.length && code[0] =='\n')
        {
            code = code[1 .. $];
            if (ctx == ParseContext.none)
                goto again;
            return null;
        }

        remark.parser.unexpectedChar();
        return null;
    }




    private:




    Asi parseVar (ParseContext ctx, ref dstring code, Asi prevAsi, 
                  EvalStrategy es, bool onSameLineOnly, dstring varKeyword)
    {
        Asi res;

        skipWhite(code);
        if (matchOp(code, "="))
        {
            remark.parser.varNameIsMissing();
            auto val = parseAsi(ParseContext.var, code, null, es, true);
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
            return new Var(new Assign (new Ident("<missing>"), exp));
        }
        else if (peekIdent(code, "var"))
        {
            remark.parser.redundantVarKeyword();
            return new Err(new Ident(varKeyword));
        }
                
        res = parseAsi(ParseContext.var, code, null, es, onSameLineOnly);

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
            return new Var(new Assign(new Ident("<missing>"), exp));
        }

        if (res)
        {
            remark.parser.expOrStmInsteadOfVarNameFound();
            return new Var(new Assign(new Ident("<missing>"), new Err(res)));
        }

        remark.parser.varNameIsMissing();
        return new Var(new Ident("<missing>"));
    }




    Exp parseIdentOrAssign (ParseContext ctx, ref dstring code, Asi prevAsi, 
                            EvalStrategy es, bool onSameLineOnly, dstring identStr)
    {
        auto ident = new Ident(identStr);
        skipWhite(code);
        auto mEq = matchOp(code, "=");

        if (ctx != ParseContext.var && !mEq)
            return ident;

        auto val = parseAsi(ParseContext.assign, code, null, es, onSameLineOnly);

        if (!val)
        {
            if (!mEq)
                return ident;

            remark.parser.varValueIsMissing();
            return new Assign(ident, new Missing);
        }

        if (!mEq)
            remark.parser.varEqualsIsMissing();

        auto exp = cast(Exp)val;
        if (exp)
            return new Assign(ident, exp);

        remark.parser.varValueIsNotExp();
        return new Assign(ident, new Err(val));
    }
    



    Exp parseOpApply (ParseContext ctx, ref dstring code, Asi prevAsi, 
                      EvalStrategy es, bool onSameLineOnly, dstring opStr)
    {
        auto op1 = prevAsi;
        auto op2 = parseAsi(ParseContext.op, code, null, es, onSameLineOnly);

        if (!op1 && !op2)
        {
            remark.parser.opWithoutOperands();
            op1 = new Missing;
            op2 = new Missing;
        }
        else if (!op1)
        {
            remark.parser.expExpectedBeforeOp();
            op1 = new Missing;
        }
        else if (!op2)
        {
            remark.parser.expExpectedAfterOp();
            op2 = new Missing;
        }

        auto stm1 = cast(Stm)op1;
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

        return new OpApply(opStr, sureCast!Exp(op1), sureCast!Exp(op2));
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




dstring peekIdent(const dstring code2, const dstring s)
{
    dstring code = code2;
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