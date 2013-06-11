module remarks;

import utils, common;

@safe nothrow:


enum RemarkSeverity { notice, suggestion, warning, error, blocker }


struct Remark
{
    RemarkSeverity severity;
    dstring name;
    dstring text;
}



interface IRemarkPrinter
{
    nothrow void print (Remark r);
}


final class RemarkPrinter : IRemarkPrinter
{
    nothrow:

    private IPrinter printer;

    this (IPrinter printer) { this.printer = printer; }

    void print (Remark r)
    {
        printer.print(r.severity.toDString());
        printer.print(" [");
        printer.print(r.name);
        printer.print("] ");
        printer.println(r.text);
    }
}


final class RemarkCollector : IRemarkPrinter
{
    nothrow:

    Remark[] remarks;

    void print (Remark r) { remarks ~= r; }
    void clear () { remarks = null; }
}


final class Remarker
{
    nothrow:

    ParserRemarks parser;

    this (IRemarkPrinter rp)
    {
        parser = new ParserRemarks(rp);
    }
}


final class ParserRemarks
{
    nothrow:

    private IRemarkPrinter rp;

    this (IRemarkPrinter rp) { this.rp = rp; }


    private void r(RemarkSeverity serverity, string name, dstring text)
    {
        rp.print(Remark(RemarkSeverity.error,
                        lastItemInList(name, '.').toDString(),
                        text));
    }

    void expExpectedBeforeOp ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
            "Expression expected before operator");
    }


    void expExpecteAfterOp ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
            "");
    }

    
    void expExpectedBeforeOpButStmFound ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
            "Expression expected before operator, not statement");
    }


    void expExpectedAfterOpButStmFound ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
            "");
    }


    void opWithoutOperands ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
            "");
    }


    void numberNotInRange ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
            "Number must be in range 0 - 9'223 372 036'854 775 807");
    }
}