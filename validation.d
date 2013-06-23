module validation;

import common, ast;


@safe nothrow:




final class NameValidator : AsiVisitor!void
{
    nothrow:
  
    private EvalStrategy es;
    bool[dstring] vars;
    bool declare;


    void validate (Asi[] asis, EvalStrategy es)
    {
        if (!asis)
            return;

        this.es = es;

        foreach (a; asis[0 ..$ - 1])
            a.accept(this);

        asis[$ - 1].accept(this);
    }


    void visit (Var v)
    {
        declare = true;
        v.exp.accept(this);
        declare = false;
    }


    void visit (Missing m)
    {
    }


    void visit (Err er)
    {
        if (es == EvalStrategy.lax && er.asi)
            er.asi.accept(this);
    }


    void visit (Ident i)
    {
        if (declare)
        {
            auto v = i.name in vars;
            if (v)
                remark.nameValidator.indetifierAlreadyDefined(i.name);
            else
                vars[i.name] = true;
            declare = false;
        }
        else
        {
            auto v = i.name in vars;
            if (!v)
                remark.nameValidator.indetifierUndefined(i.name);
        }
    }


    void visit (Assign a)
    {
        a.ident.accept(this);
        a.value.accept(this);
    }


    void visit (Int i)
    {
    }


    void visit (OpApply opa)
    {
        opa.op1.accept(this);
        opa.op2.accept(this);
    }
}