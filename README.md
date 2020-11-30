# mincmd
Mincmd is a commandline wrapper for Windows. It's based on Mintty and Conpty and adds some nice features to the Windows cmd.

## What is it exactly?
Basically it is an AutoHotKey script which is used to create a mintty window with conpty wrapper and clink injected to cmd.exe. Furthermore it adds a way to configure aliases via scripts. They will be prepended to the PATH environment variable. For example:

### Cygwin bash configuration:
```
--- Settings ---
Replaces the "open commandprompt here" action in shift + rightclick menu (Windows 7)
Ersetzt die "Kommandozeile hier öffnen" option im Shift + Rechtsklick Menü (Windows 7)
registerContextMenu=false


--- Environment ---
First define Variables here before they can be added to PATH!
Zuerst Umgebungsvariablen definieren, bevor sie der PATH-Variable hinzugefügt werden können!
cygwinDir=%HOMEDRIVE%\cygwin64\bin
prependPath=
appendPath=%cygwinDir%

Every single line without an equalsign can be a comment!
Solange keine Gleichzeichen vorkommen, kann jede leere Zeile zum Kommentieren benutzt werden!


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
