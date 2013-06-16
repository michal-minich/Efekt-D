module tests.utils;

import std.stdio;
import utils, exceptions, remarks;

@safe nothrow version (unittest):


@trusted void check (bool test, string msg)
{
    check(test, msg.toDString());
}


@trusted void check (bool test, dstring msg)
{
    debug
    {
        if (!test)
            dontThrow(writeln(msg));
    }
    else
    {
        if (msg)
            assert (test, msg);
        else
            assert (test);
    }
}


void verifyRemarks(dstring code, bool hasError, RemarkCollector rc, dstring[] names ...)
{
    if (hasError)
        assert(names.length, "Parser is expected to have some remarks when it has error");

    if (rc.remarks.length == names.length)
    {
        foreach (ix, n; names)
            check(rc.remarks[ix].name == n, "Other remark found '" ~ code ~ "' -> '"
                  ~ rc.remarks[ix].name ~ "' != '" ~ n ~ "'");
    }
    else
    {
        dbg("Expected " ~ names.length.toDString() ~ " remarks," ~
            "found " ~ rc.remarks.length.toDString() ~ " '" ~ code ~ "'");
        foreach (r; rc.remarks)
            dbg("\t", r.name);
    }


    rc.clear();
}


void verifyExceptions(dstring code, ExceptionCollector ec, dstring[] names ...)
{
    if (ec.exceptions.length == names.length)
    {
        foreach (ix, n; names)
            check(ec.exceptions[ix].name == n, "Other exception found '" ~ code ~ "' -> '"
                  ~ ec.exceptions[ix].name ~ "' != '" ~ n ~ "'");
    }
    else
    {
        dbg("Expected " ~ names.length.toDString() ~ " exceptions," ~
            "found " ~ ec.exceptions.length.toDString() ~ " '" ~ code ~ "'");
        foreach (e; ec.exceptions)
            dbg("\t", e.name);
    }

    ec.clear();
}