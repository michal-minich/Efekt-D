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


void verifyRemarks(bool hasError, RemarkCollector rc, dstring[] names ...)
{
    if (hasError)
        assert(names.length, "Parser is expected to have some remarks when it has error");

    assert(rc.remarks.length == names.length);
    foreach (ix, n; names)
        check(rc.remarks[ix].name == n, "Other remark found '"
              ~ rc.remarks[ix].name ~ "' != '" ~ n ~ "'");

    rc.clear();
    assert(!rc.remarks.length);
}


void verifyExceptions(ExceptionCollector ec, dstring[] names ...)
{
    assert(ec.exceptions.length == names.length);
    foreach (ix, n; names)
        check(ec.exceptions[ix].name == n, "Other exception found '"
              ~ ec.exceptions[ix].name ~ "' != '" ~ n ~ "'");

    ec.clear();
    assert(!ec.exceptions.length);
}