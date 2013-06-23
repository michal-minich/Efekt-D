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
    auto res = "";
    foreach (t; T)
    {
        immutable ts = "const(" ~ t.stringof ~ ")";
        pragma (msg, ts);
        res ~= "const nothrow pure override @disable @property " ~ ts
            ~ " as" ~ t.stringof ~ " () { return this; } ";
    }
    return res;
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
    
    enum castThis = q{ return cast(typeof(return))this; };

    const pure @property:
    // stm
    const(Stm) asStm () { mixin(castThis); }
    const(Var) asVar () { mixin(castThis); }

    // exp
    const(Exp) asExp () { mixin(castThis); }
    const(Missing) asMissing () { mixin(castThis); }
    const(Err) asErr () { mixin(castThis); }
    const(Ident) asIdent () { mixin(castThis); }
    const(Assign) asAssign () { mixin(castThis); }
    const(Int) asInt () { mixin(castThis); }
    const(OpApply) asOpApply () { mixin(castThis); }
}




abstract class Stm : Asi
{
    mixin (disable!(typeof(this)));

    // disable classes derived form Exp as they will always be null
    const nothrow pure @disable override @property:
    const(Exp) asExp () { return null; }
    const(Missing) asMissing () { return null; }
    const(Err) asErr () { return null; }
    const(Ident) asIdent () { return null; }
    const(Assign) asAssign () { return null; }
    const(Int) asInt () { return null; }
    const(OpApply) asOpApply () { return null; }
}




abstract class Exp : Asi
{
    mixin (disable!(typeof(this)));

    // disable classes derived form Stm as they will always be null
    const nothrow pure @disable override @property:
    const(Stm) asStm () { return null; }
    const(Var) asVar () { return null; }
}




final class Var : Stm
{
    mixin Acceptors!();
    mixin (disable!(typeof(this)));

    nothrow:

    Exp pExp;

    this (Err err) { pExp = err; }
    this (Ident ident) { pExp = ident; }
    this (Assign ass) { pExp = ass; }

    invariant () { assert (pExp && (pExp.asIdent || pExp.asAssign || pExp.asErr)); }

    pure @property:

    Exp exp () { return pExp; }
}




final class Missing : Exp
{
    mixin Acceptors!();
    mixin (disable!(typeof(this)));
    
    nothrow:
    this () { }
}




final class Err : Exp
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




final class Assign : Exp
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
