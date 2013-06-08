module main;


import std.stdio;
import parser;


int main(string[] argv)
{
    auto asis = parse(" \t 123  ");

    foreach (a; asis)
        writeln("\"", a.text, "\"");

    readln();

    return 0;
}
