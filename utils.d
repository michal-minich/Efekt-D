module utils;


@safe nothrow:


@trusted void dontThrow (lazy void fn)
{
    try
    {
        fn();
    }
    catch (Exception ex)
    {
        assert (false, ex.toString());
    }
}