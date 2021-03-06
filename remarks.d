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
    NameValidatorRemarks nameValidator;

    this (IRemarkPrinter rp)
    {
        parser = new ParserRemarks(rp);
        nameValidator = new NameValidatorRemarks(rp);
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

    void expExpectedAfterOp ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
            "Expression expected after operator");
    }
    
    void expExpectedBeforeOpButStmFound ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
            "Expression expected before operator, not statement");
    }

    void expExpectedAfterOpButStmFound ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
            "Expression expected after operator, not statement");
    }

    void opBetweenStatements ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
          "Operator should be placed between expressions, not statements");
    }

    void opWithoutOperands ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
            "Expression expected before and after operator");
    }

    void numberNotInRange ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
            "Number must be in range 0 - 9'223 372 036'854 775 807");
    }

    void unexpectedChar ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
          "Unexpected character");
    }

    void varNameIsMissing ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
          "Variable name is missing");
    }

    void expOrStmInsteadOfVarNameFound ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
          "Variable name was expected, but expression or statement found");
    }

    void varEqualsIsMissing ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
          "Expected equals and expression to be assigned to value");
    }

    void varValueIsMissing ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
          "Expected expression after equal sign");
    }

    void varValueIsNotExp ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
          "An expression should be assigned to variable, not statement");
    }

    void redundantVarKeyword ()
    {
        r(RemarkSeverity.error, __FUNCTION__, 
          "Keyword 'var' is redundant.");
    }
}




final class NameValidatorRemarks
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
    
    void indetifierUndefined (dstring name)
    {
        r(RemarkSeverity.error, __FUNCTION__, 
          "Identifier '" ~ name ~ "' is not yet defined.");
    }
    
    void indetifierAlreadyDefined (dstring name)
    {
        r(RemarkSeverity.error, __FUNCTION__, 
          "Identifier '" ~ name ~ "' is already defined.");
    }
}