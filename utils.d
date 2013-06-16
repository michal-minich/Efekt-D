module utils;

import std.stdio, std.conv;

@safe nothrow:


@trusted R dontThrow (R) (lazy R fn)
{
    try
        return fn();
    catch (Exception ex)
        assert (false, ex.toString());
}


@trusted dstring toDString (T) (const T a) 
    if (is (T == enum) || is (T == string) ||is (T == long) || is (T == size_t))
{
    try
        return a.to!dstring();
    catch (Exception ex)
        assert (false, ex.toString());
}


@trusted string toString (const dstring s) 
{
    try
        return s.to!string();
    catch (Exception ex)
        assert (false, ex.toString());
}


@trusted string toString (const size_t s) 
{
    try
        return s.to!string();
    catch (Exception ex)
        assert (false, ex.toString());
}


@trusted pure B sureCast (B, A) (A a)
{
    debug
    {
        auto res = cast(B)a;
        if (a)
            assert(res);
        return res;
    }
    else
    {
        return cast(B)cast(void*)a;
    }
}


debug @trusted void dbg (Args...) (Args args)
{
    try
        writeln(args);
    catch (Exception ex)
        assert (ex.msg);
}


pure size_t lastIndexOf (const string items, char item)
{
    foreach_reverse (ix, i; items)
        if (i == item)
            return ix;

    assert (false, "item '" ~ item ~ "' not found.");
}


pure string lastItemInList (const string list, char separator)
{
    return list[list.lastIndexOf(separator) + 1 .. $];
}


pure size_t count (T, U) (const T[] items, const U item)
{
    size_t c;
    foreach (i; items)
        if (i == item)
            ++c;
    return c;
}