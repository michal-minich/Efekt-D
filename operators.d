module operators;

import utils, common, ast, exceptions;

@safe nothrow:


alias opFn = Exp function (EvalStrategy, Thrower, Exp, Exp);

opFn[dstring] ops;


static this ()
{
    ops = ["+" : &plus,
           "-" : &minus];
}


@trusted Exp plus (EvalStrategy es, Thrower th, Exp op1, Exp op2)
{
    immutable o1 = sureCast!Int(op1).asLong;
    immutable o2 = sureCast!Int(op2).asLong;
    auto res = o1 + o2;
    asm { jo overflowed; }
    return new Int(res);
    overflowed:
    if (es == EvalStrategy.throwing)
    {
        th.integerOwerflow();
        return null;
    }
    else if (es == EvalStrategy.strict)
        return new Int(res);
    else
        return new Int(long.max);
}


@trusted Exp minus (EvalStrategy es, Thrower th, Exp op1, Exp op2)
{
    immutable o1 = sureCast!Int(op1).asLong;
    immutable o2 = sureCast!Int(op2).asLong;
    auto res = o1 - o2;
    asm { jo overflowed; }
    return new Int(res);
    overflowed:
    if (es == EvalStrategy.throwing)
    {
        th.integerOwerflow();
        return null;
    }
    else if (es == EvalStrategy.strict)
        return new Int(res);
    else
        return new Int(long.max);
}
