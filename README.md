# mincmd
Mincmd is a commandline wrapper for Windows. It's based on Mintty and Conpty and adds some nice features to the Windows cmd.

## What is it exactly?
Basically it is an AutoHotKey script which is used to create a mintty window with conpty wrapper and clink injected to cmd.exe. Furthermore it adds a way to configure aliases via scripts. They will be prepended to the PATH environment variable. For example:

### Cygwin bash configuration:
```
--- Environment ---
cygwinDir=%HOMEDRIVE%\cygwin64\bin
appendPath=%cygwinDir%


--- Alias ---
name=bash
type=cmd
----- AliasScript_Start -----
@echo off
pushd "%cygwinDir%\.."
set "HOME=`%cd`%\home\%USERNAME%"
popd
"%cygwinDir%\bash" --login -i
----- AliasScript_Stop -----
```
