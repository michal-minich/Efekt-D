@echo off
move /Y tests-all.lst tests\all.lst 2> nul
move /Y tests-interpreter.lst tests\interpreter.lst 2> nul
move /Y tests-parser.lst tests\parser.lst 2> nul
move /Y tests-utils.lst tests\utils.lst 2> nul
echo off