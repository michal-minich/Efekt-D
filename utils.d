module utils;

import std.conv;

@safe nothrow:


@trusted R dontThrow (R) (lazy R fn)
{
    try
    {
        return fn();
    }
    catch (Exception ex)
    {
        assert (false, ex.toString());
    }
}


@trusted toDString (long l)
{
    try
    {
        return l.to!dstring();
    }
    catch (Exception ex)
    {
        assert (false, ex.toString());
    }
}


@trusted B sureCast (B, A) (A a)
{
    debug
    {
        auto res = cast(B)a;
        assert(res);
        return res;
    }
    else
    {
        return cast(B)cast(void*)a;
    }
}