module ast;

import common, printer, interpreter;

@safe nothrow:


mixin template Visits ()
{
    R visit (Var);
    R visit (Missing);
    R visit (Err);
    R visit (Ident);
    R visit (Assign);
    R visit (Int);
    R visit (OpApply);
}


interface AsiVisitorThrowing (R)
{
    mixin Visits!();
}


interface AsiVisitor (R)
{
    nothrow:
    mixin Visits!();
}


mixin template Acceptors ()
{
    nothrow override void accept (AsiPrinter v) { v.visit(this); }
    override Asi accept (Interpreter v) { return v.visit(this); }
}


private @property auto disable (T...) ()
{
    return"";/*
    auto res = "";
    foreach (t; T)
        res ~=  q{const nothrow pure @disable  @property const(}
            ~ t.stringof ~ q{) as} ~ t .stringof ~ q{ () { assert(false); }};
    return res;*/
}


abstract class  Asi
{
    Asi accept (Interpreter);
    
    nothrow:    
    
    debug
    {
        string typeName;
        nothrow this () { typeName = typeid(this).name;}
    }

    void accept (AsiPrinter);
    
    pure @property const:

    enum castExp = q{assert(cast(const Exp)this); return cast(typeof(return))this;};
    enum castStm = q{assert(cast(const Stm)this); return cast(typeof(return))this;};

    const(Stm) asStm () { mixin(castStm); }
    const(Exp) asExp () { mixin(castExp); }
    const(Var) asVar () { mixin(castStm); }
    const(Missing) asMissing () { mixin(castExp); }
    const(Err) asErr () { mixin(castExp); }
    const(Ident) asIdent () { mixin(castExp); }
    const(Assign) asAssign () { mixin(castExp); }
    const(Int) asInt () { mixin(castExp); }
    const(OpApply) asOpApply () { mixin(castExp); }
}


abstract class Stm : Asi
{
    const nothrow pure @disable override @property:
    const(Stm) asStm () { assert(false); }
    const(Exp) asExp () { assert(false); }

    const(Missing) asMissing () { assert(false); }
    const(Err) asErr () { assert(false); }
    const(Ident) asIdent () { assert(false); }
    const(Assign) asAssign () { assert(false); }
    const(Int) asInt () { assert(false); }
    const(OpApply) asOpApply () { assert(false); }
}


abstract class Exp : Asi
{
    const nothrow pure @disable override @property:
    const(Stm) asStm () { assert(false); }
    const(Exp) asExp () { assert(false); }

    const(Var) asVar () { assert(false); }
}


class Var : Stm
{
    mixin Acceptors!();
    mixin (disable!(typeof(this)));

    nothrow:

    Exp pExp;

    this (Ident ident) { pExp = ident; }
    this (Assign ass) { pExp = ass; }

    invariant () { assert (pExp && (pExp.asIdent || pExp.asAssign)); }

    pure @property:

    Exp exp () { return pExp; }

    const dstring name ()
    {
        auto a = pExp.asAssign;
        if (a)
            return a.name;
        return pExp.asIdent.name;
    }
}


class Missing : Exp
{
    mixin Acceptors!();
    mixin (disable!(typeof(this)));
    
    nothrow:
    this () { }
}


class Err : Exp
{
    mixin Acceptors!();
    mixin (disable!(typeof(this)));
    
    nothrow:
    
    Asi asi;
    
    this (Asi asi) { this.asi = asi; }
    
    //invariant () { assert(asi); }
}


final class Ident : Exp
{
    mixin Acceptors!();
    mixin (disable!(typeof(this)));
    
    nothrow:
    
    dstring name;
    
    this (dstring name) { this.name = name; }
    
    invariant () { assert(name.length); }
}


class Assign : Exp
{
    mixin Acceptors!();
    mixin (disable!(typeof(this)));
    
    nothrow:
    
    dstring name;
    
    Exp value;
    
    this (dstring name, Exp value) { this.name = name; this.value = value; }

    invariant () { assert(name.length); assert(value); }
}



final class Int : Exp
{
    mixin Acceptors!();
    mixin (disable!(typeof(this)));
    nothrow:

    dstring asString;
    long asLong;

    this (long asLong) { this.asLong = asLong; }

    this (dstring asString, long asLong)
    {
        this.asString = asString;
        this.asLong = asLong;
    }
}


final class OpApply : Exp
{
    mixin Acceptors!();
    mixin (disable!(typeof(this)));
    nothrow:

    dstring op;
    Exp op1;
    Exp op2;
    
    this (dstring op, Exp op1, Exp op2)
    {
        this.op = op;
        this.op1 = op1;
        this.op2 = op2;
    }

    invariant () { assert(op.length && op1 && op2); }
}
