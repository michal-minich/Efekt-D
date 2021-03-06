module interpreter;

import utils, common, ast, remarks, exceptions, operators;

@safe nothrow:



final class Interpreter : AsiVisitorThrowing!Asi
{
    private EvalStrategy es;
    private Thrower thrower;
    Exp[dstring] vars;


    nothrow this (Thrower thrower) { this.thrower = thrower; }




    nothrow Asi run (Asi[] asis, EvalStrategy es)
    {
        if (!asis.length)
            return null;

        this.es = es;
        thrower.evalStrategy = es;

        try
        {
            foreach (a; asis[0 .. $ - 1])
                a.accept(this);
            return asis[$ - 1].accept(this);
        }
        catch (InterpreterException ex)
        {
            return null;
        }
        catch (Exception ex)
        {
            assert (false, ex.msg);
        }
    }




    private Exp eval (Exp e)
    {
        auto res = e.accept(this);
        return sureCast!Exp(res);
    }




    Var visit (Var v)
    {
        auto ass = cast(Assign)v.exp;
        if (ass)
        {
            vars[ass.ident.name] = new Missing;
            ass.accept(this);
        }
        else
        {
            auto ident = cast(Ident)v.exp;
            vars[ident.name] = new Missing;
        }
        return null;
    }




    Missing visit (Missing m)
    {
        if (es == EvalStrategy.throwing)
            thrower.cannotEvalMissing();

        return m;
    }




    Asi visit (Err er)
    {
        final switch (es) with (EvalStrategy)
        {
            case throwing:
                thrower.cannotEvalError();
                assert(false);
            case strict:
                return er;
            case lax:
                return er.asi ? er.asi : er;
        }
    }

    


    Exp visit (Ident i)
    {
        auto var = i.name in vars;
        if (var)
            return eval(*var);
        
        thrower.undefinedVariable(i.name);
        return new Missing;
    }




    Exp visit (Assign a)
    {
        auto val = eval(a.value);
        auto var = a.ident.name in vars;
        if (var)
            *var = val;
        else
        {
            thrower.undefinedVariable(a.ident.name);
            vars[a.ident.name] = val;
        }

        return val;
    }

    


    Int visit (Int i) { return i; }




    Exp visit (OpApply opa)
    {
        auto o1 = eval(opa.op1);
        auto o2 = eval(opa.op2);
        Exp firstGood;

        if (es == EvalStrategy.throwing)
        {
            Asi x = cast(Missing)o1;
            if (!x)
                x = cast(Missing)o2;
            if (x)
            {
                thrower.cannotEvalMissing();
                return null;
            }

            x = cast(Err)o1;
            if (!x)
                x = cast(Err)o2;
            if (x)
            {
                thrower.cannotEvalError();
                return null;
            }
        }
        else if (es == EvalStrategy.strict)
        {
            Asi x = cast(Missing)o1;
            if (x)
                return new Err(opa);

            x = cast(Err)o1;
            if (x)
                return new Err(opa);

            x = cast(Missing)o2;
            if (x)
                return new Err(opa);

            x = cast(Err)o2;
            if (x)
                return new Err(opa);
        }
        else
        {
            Asi x = cast(Missing)o1;
            if (x)
                o1 = new Int(0);
            else
            {
                x = cast(Err)o1;
                if (x)
                    o1 = new Int(0);
                else
                    firstGood = o1;
            }

            x = cast(Missing)o2;
            if (x)
                o2 = new Int(0);
            else
            {
                x = cast(Err)o2;
                if (x)
                    o2 = new Int(0);
                else if (!firstGood)
                    firstGood = o2;
            }
        }

        auto opfn = opa.op in ops;
        if (opfn)
            return (*opfn)(es, thrower, o1, o2);

        thrower.opeatorIsUndefined (opa.op);

        final switch (es) with (EvalStrategy)
        {
            case throwing:
                return null;
            case strict:
                return new Err(opa);
            case lax:
                assert (firstGood);
                return firstGood;
        }        
    }
}