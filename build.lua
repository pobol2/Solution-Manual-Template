-- Regression tests for the shared classes, isolated from project customizations.
module = "solution-manual"
sourcefiledir = "solution-manual"
sourcefiles = {"*.cls", "*.def"}
installfiles = {"*.cls", "*.def"}
unpackfiles = {}
typesetfiles = {}
-- The default cleanfiles includes *.pdf: preserve the committed previews.
cleanfiles = {}

-- Keep l3build clean/check away from the manual's existing build outputs.
builddir = "build/l3build"
testfiledir = "testfiles"
-- SolutionFigure requires LuaLaTeX; use it for both classes.
checkengines = {"luatex"}
stdengine = "luatex"
checkruns = 2
forcecheckruns = true
-- Unexpected TeX errors must fail even outside the captured log region.
recordstatus = true
-- MiKTeX's LuaTeX wraps at 79 columns; match it on TeX Live as well.
maxprintline = 79
