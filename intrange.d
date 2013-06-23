module intrange;

import common, ast, interpreter;


@safe nothrow:




final class IntRange : AsiVisitor!void
{
    nothrow:
  

    struct Rng { long min; long max; }


    private EvalStrategy es;
    private Interpreter interpreter;
    private Ident toAssign;
    private Rng[dstring] vars;



    
    
    this (Interpreter interpreter) { this.interpreter = interpreter; }




    void calculate (Asi[] asis, EvalStrategy es)
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
        v.exp.accept(this);
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
        auto vp = i.name in vars;
        if (vp)
        {
            auto v = *vp;
            i.min = v.min;
            i.max = v.max;
        }
    }


    void visit (Assign a)
    {
        //a.ident.accept(this);
        toAssign = a.ident;
        a.value.accept(this);
        a.ident.min = a.value.min;
        a.ident.max = a.value.max;
        vars[a.ident.name] = Rng(a.value.min, a.value.max);
    }


    void visit (Int i)
    {
        i.min = i.asLong;
        i.max = i.asLong;
    }


    void visit (OpApply opa)
    {
        opa.op1.accept(this);
        opa.op2.accept(this);

        auto expMin = interpreter.run(
            [new OpApply(opa.op, new Int(opa.op1.min), new Int(opa.op2.min))],
            EvalStrategy.strict);
        opa.min = expMin.asInt.asLong;
        
        auto expMax = interpreter.run(
            [new OpApply(opa.op, new Int(opa.op1.max), new Int(opa.op2.max))],
            EvalStrategy.strict);
        opa.max = expMax.asInt.asLong;
    }
}