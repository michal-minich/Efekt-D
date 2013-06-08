module ast;


@safe:


abstract class  Asi
{
    nothrow:
    dstring text;
    this (dstring txt) { text = txt; }
}


abstract class Exp : Asi
{
    nothrow:
    this (dstring txt) { super (txt); } 
}


final class Int : Exp
{
    nothrow:
    this (dstring txt) { super (txt); } 
}


final class OpApply : Exp
{
    nothrow:
    this (dstring txt) { super (txt); } 
}
