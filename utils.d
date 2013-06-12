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


@trusted dstring toDString (T) (T a) 
    if (is (T == enum) || is (T == string)||is (T == long))
{
    try
    {
        return a.to!dstring();
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


size_t lastIndexOf (string items, char item)
{
    foreach_reverse (ix, i; items)
        if (i == item)
            return ix;

    assert (false, "item '" ~ item ~ "' not found.");
}


string lastItemInList (string list, char separator)
{
    return list[list.lastIndexOf(separator) + 1 .. $];
}


version (unittest) @trusted void check (bool test, string msg = null)
{
    debug
    {
        if (!test)
            dontThrow(std.stdio.writeln(msg));
    }
    else
    {
        if (msg)
            assert (test, msg);
        else
            assert (test);
    }
}