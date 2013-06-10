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


@trusted dstring toDString (long l)
{
    return dontThrow(l.to!dstring());
}


@trusted dstring toDString (string s)
{
    return dontThrow(s.to!dstring());
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