# mincmd
Mincmd is a commandline wrapper for Windows. It's based on Mintty and Conpty and adds some nice features to the Windows cmd. Clink will be injected on every start to use autocompletion and command history.

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
set "HOME=%cd%\home\%USERNAME%"
popd
"%cygwinDir%\bash" --login -i
----- AliasScript_Stop -----
```

As you can see you can add custom environment variables.

## What it is not?
It's no cmd.exe replacement! It also does not work like conemu or cmder. It does not hook into Windows apis. But it can replace the default right-click-menu open commandprompt here action (when started as admin and configured correctly).

## How to install?
Download the latest release of mincmd.exe and start it somewhere (you should start it in an empty folder which will be the home folder of mincmd). Wait a minute until it's ready (it should start immediatly after downloading needed components) and be happy!

## How to configure?
### mintty
You can configure the mintty window by right-clicking into it and choosing options. Here you can change the design and the window, keyboard and mouse behaviour.

### clink
The clink configfile ("settings") will be created after starting mincmd for the first time. You can change it in the profile directory of mincmd.

### mincmd
There is a configfile for mincmd called mincmd_settings.ini. You can change it in the profile directory. The default configfile is made to work on Windows 7 with cygwin installed. That means you can type `bash` and the cygwin bash opens. If you want to use the WSL bash instead you can go to the config file, which should look like this:
```
--- Settings ---
registerContextMenu=false


--- Environment ---
Zuerst Umgebungsvariablen definieren, bevor sie der PATH-Variable hinzugefügt werden können!
cygwinDir=C:\CygwinPortable\App\Runtime\cygwin\bin
prependPath=
appendPath=%cygwinDir%

Solange keine Gleichzeichen vorkommen, kann jede leere Zeile zum Kommentieren benutzt werden!


--- Alias ---
name=bash
type=cmd
----- AliasScript_Start -----
@echo off
pushd "%cygwinDir%\.."
set "HOME=%cd%\home\%USERNAME%"
popd
"%cygwinDir%\bash" --login -i
----- AliasScript_Stop -----
```
 and change it to this:
 ```
 --- Settings ---
registerContextMenu=false


--- Environment ---
Zuerst Umgebungsvariablen definieren, bevor sie der PATH-Variable hinzugefügt werden können!
prependPath=
appendPath=

Solange keine Gleichzeichen vorkommen, kann jede leere Zeile zum Kommentieren benutzt werden!


--- Alias ---
 ```
 
 If you want to use the shift + right-click-menu shortcut, set `registerContextMenu=false` to `registerContextMenu=true` (not yet working properly).
 You can define your own environment variables after `--- Environment ---`.
 Set the `prependPath` or `appendPath` variable to add something to your PATH variable. You can also add variables set before.
 You can comment your configfile in every empty line. But you can't use equal signs in your comments. They would mess up your environment variables.
