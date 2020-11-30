#NoTrayIcon
#NoEnv
#SingleInstance, Force

SetWorkingDir, %A_ScriptDir%

/* First start setup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Run this on first startup (if no files exist) ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
*/
If (not FileExist("clink*.*") and not FileExist("cygwin1.dll") and not FileExist("mintty.exe") and not FileExist("winpty*.*"))
{
	DownloadLatestMintty()
	DownloadLatestWinPty()
	DownloadLatestClink()
	Sleep, 1000
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

If (not InStr(FileExist("profile"), "D"))
	FileCreateDir, profile

SetWorkingDir, profile
If not FileExist("mincmd_settings.ini")
{
	FileAppend,
	(
--- Settings ---
registerContextMenu=false


--- Environment ---
Zuerst Umgebungsvariablen definieren, bevor sie der PATH-Variable hinzugefügt werden können!
cygwinDir=`%HOMEDRIVE`%\cygwin64\bin
prependPath=
appendPath=`%cygwinDir`%

Solange keine Gleichzeichen vorkommen, kann jede leere Zeile zum Kommentieren benutzt werden!


--- Alias ---
name=bash
type=cmd
----- AliasScript_Start -----
@echo off
pushd "`%cygwinDir`%\.."
set "HOME=`%cd`%\home\`%USERNAME`%"
popd
"`%cygwinDir`%\bash" --login -i
----- AliasScript_Stop -----
	), mincmd_settings.ini
}
SetWorkingDir, %A_ScriptDir%

contextMenu = false

SettingsSection = false
EnvSection = false
AliasSection = false
AliasScriptSection = false

Loop, read, %A_ScriptDir%\profile\mincmd_settings.ini
{
    Loop, parse, A_LoopReadLine, %A_Tab%
    {
		readLine = %A_LoopField%
		
		IfInString, readLine, --- Settings ---
		{
			SettingsSection = true
			EnvSection = false
			AliasSection = false
			AliasScriptSection = false
			continue
		}
		
		IfInString, readLine, --- Environment ---
		{
			SettingsSection = false
			EnvSection = true
			AliasSection = false
			AliasScriptSection = false
			continue
		}
		
		IfInString, readLine, --- Alias ---
		{
			SettingsSection = false
			EnvSection = false
			AliasSection = true
			AliasScriptSection = false
			continue
		}
		
		If (%SettingsSection% == true)
		{
			IfInString, readLine, registerContextMenu=
			{
				EnvGet, oldPATH, PATH
				EqIndex := InStr(readLine, "=")
				contextMenu := SubStr(readLine, EqIndex + 1)
				continue
			}
		}
		
		If (%EnvSection% == true)
		{
			While (True)
			{
				indexI := InStr(readLine, "%",,, 1)
				indexII := InStr(readLine, "%",,, 2)
				If (indexII > indexI > 0)
				{
					foundStr := SubStr(readLine, indexI, (indexII - indexI + 1))
					envVar := StrReplace(foundStr, "%", "")
					EnvGet, repStr, % envVar ; Evaluiere envVar zu Variablennamen aus Configfile und hole Umgebungsvariable. repStr := %envVar% bei internen Variablen
					readLine := StrReplace(readLine, foundStr, repStr)
				}
				else
					break
			}
			
			IfInString, readLine, prependPath=
			{
				EnvGet, oldPATH, PATH
				EqIndex := InStr(readLine, "=")
				envVal := SubStr(readLine, EqIndex + 1)
				EnvSet, PATH, %envVal%;%oldPATH%
				continue
			}
			
			IfInString, readLine, appendPath=
			{
				EnvGet, oldPATH, PATH
				EqIndex := InStr(readLine, "=")
				envVal := SubStr(readLine, EqIndex + 1)
				EnvSet, PATH, %oldPATH%;%envVal%
				continue
			}
			
			IfInString, readLine, =
			{
				EqIndex := InStr(readLine, "=")
				envName := SubStr(readLine, 1, EqIndex - 1)
				envVal := SubStr(readLine, EqIndex + 1)
				EnvSet, %envName%, %envVal%
				continue
			}
		}
		
		If (%AliasSection% == true)
		{
			If (not %AliasScriptSection%)
			{
				IfInString, readLine, name=
				{
					EqIndex := InStr(readLine, "=")
					AliasName := SubStr(readLine, EqIndex + 1)
				}
				
				IfInString, readLine, type=
				{
					EqIndex := InStr(readLine, "=")
					AliasType := SubStr(readLine, EqIndex + 1)
				}
				
				IfInString, readLine, ----- AliasScript_Start -----
				{
					AliasScriptSection = true
					continue
				}
			}
			
			IfInString, readLine, ----- AliasScript_Stop -----
			{
				AliasScriptSection = false
			}
			
			If (%AliasScriptSection%)
			{
				AliasScript = %AliasScript%%readLine%`n
				continue
			}
			
			If (AliasName and AliasType and AliasScript and not %AliasScriptSection%)
			{
				SetWorkingDir, profile
				If (not InStr(FileExist("alias"), "D"))
					FileCreateDir, alias
				SetWorkingDir, alias
				AliasFile = %AliasName%.%AliasType%
				If (FileExist(AliasFile))
					FileDelete, %AliasFile%
				FileAppend, %AliasScript%, %AliasName%.%AliasType%
				AliasName =
				AliasType =
				AliasScript =
				SetWorkingDir, %A_ScriptDir%
			}
		}
	}
}

oriVal = cmd.exe /s /k pushd "`%V"
newVal = %A_ScriptFullPath%
RegRead, currVal, HKCR, \Directory\shell\cmd\command

If (%contextMenu% == true)
{
	If (currVal == oriVal)
	{
		RegWrite, REG_SZ, HKEY_CLASSES_ROOT\Directory\shell\cmd\command,, %newVal%
		RegWrite, REG_SZ, HKEY_CLASSES_ROOT\Drive\shell\cmd\command,, %newVal%
		If (ErrorLevel == 1)
			MsgBox, Bitte als Admin starten, damit mincmd im Kontextmenü auftaucht!
	}
}
Else
{
	If (currVal == newVal)
	{
		RegWrite, REG_SZ, HKEY_CLASSES_ROOT\Directory\shell\cmd\command,, %oriVal%
		RegWrite, REG_SZ, HKEY_CLASSES_ROOT\Drive\shell\cmd\command,, %oriVal%
		If (ErrorLevel == 1)
			MsgBox, Bitte als Admin starten!
	}
}

EnvGet, oldPATH, PATH
EnvSet, PATH, %A_ScriptDir%\profile\alias;%oldPATH%
SetWorkingDir, %A_ScriptDir%

paramList = 
for n, param in A_Args
{
	paramList = %paramList% %param%
}

clink_arch = x86
If (A_Is64bitOS)
	clink_arch = x64
clinkExe = %A_ScriptDir%\clink_%clink_arch%.exe

EnvGet, cmdExe, ComSpec
gosub, Start
return

!F2::
If (WinActive("ahk_exe mintty.exe ahk_class mintty"))
	gosub, Start
return

Start:
Run, %A_ScriptDir%\mintty.exe -d -c "%A_ScriptDir%\profile\mintty_config.ini" -e "%A_ScriptDir%\winpty.exe" "%cmdExe%" %paramList% /K "%clinkExe%" inject && title %ComSpec%,,, minPID

while (not WinExist("ahk_exe mintty.exe ahk_class ConsoleWindowClass") and not WinExist("ahk_pid %minPID%"))
	Sleep, 0 ; Do nothing. Just wait for window. Works better than wait for a hidden window to exist

WinHide, ahk_pid %minPID%
SetTimer, checkProcess, 2000
return

checkProcess:
If (not WinExist("ahk_exe mintty.exe ahk_class mintty"))
	ExitApp
return


;;;;;;;;; Needed for first time setup ;;;;;;;;;;

DownloadLatestClink()
{
	URLDownloadToFile, https://github.com/mridgers/clink/releases/latest, clink_version.html
	
	Loop, read, %A_ScriptDir%\clink_version.html
	{
		Loop, parse, A_LoopReadLine, %A_Tab%
		{
			If (RegExMatch(A_LoopReadLine, "Release.*[0-9.]+", clink_version) > 0)
			{
				found = true
				RegExMatch(clink_version, "[0-9.]+", clink_version)
				break
			}
		}
		If (%found% == true)
			break
	}
	
	FileDelete, clink_version.html
	URLDownloadToFile, https://github.com/mridgers/clink/releases/download/%clink_version%/clink_%clink_version%.zip, clink.zip
	
	Unzip("clink.zip")
	FileDelete, clink.zip
	
	clinkDir = clink_%clink_version%
	FileCopy, %clinkDir%\clink.lua, %A_ScriptDir%
	FileCopy, %clinkDir%\clink_dll*.dll, %A_ScriptDir%
	FileCopy, %clinkDir%\clink_x*.exe, %A_ScriptDir%
	
	FileRemoveDir, %clinkDir%, 1
}

DownloadLatestTarTool()
{
	URLDownloadToFile, https://github.com/senthilrajasek/tartool/releases/latest, tarTool_version.html
	
	Loop, read, %A_ScriptDir%\tarTool_version.html
	{
		Loop, parse, A_LoopReadLine, %A_Tab%
		{
			If (RegExMatch(A_LoopReadLine, "/.*TarTool.zip", tarTool_version) > 0)
			{
				found = true
				;RegExMatch(tarTool_version, "[0-9.]+", tarTool_version)
				break
			}
		}
		If (%found% == true)
			break
	}
	
	FileDelete, tarTool_version.html
	URLDownloadToFile, https://github.com%tarTool_version%, tarTool.zip
	Unzip("tarTool.zip")
	
	FileDelete, tarTool.zip
}

DownloadLatestWinPty()
{
	URLDownloadToFile, https://github.com/rprichard/winpty/releases/latest, winPty_version.html
	foundWinPty = false
	foundCygWin = false
	
	Loop, read, %A_ScriptDir%\winPty_version.html
	{
		Loop, parse, A_LoopReadLine, %A_Tab%
		{
			If ((%foundWinPty% == false) and (RegExMatch(A_LoopReadLine, "Release.*[0-9.]+", winPty_version) > 0))
			{
				foundWinPty = true
				RegExMatch(winPty_version, "[0-9.]+", winPty_version)
				break
			}
			
			If ((%foundCygWin% == false) and (RegExMatch(A_LoopReadLine, "cygwin-[0-9.]+", cygWin_version) > 0))
			{
				foundCygWin = true
				RegExMatch(cygWin_version, "[0-9.]+", cygWin_version)
				break
			}
		}
		If (%foundWinPty% == true and %foundCygWin% == true)
			break
	}
	
	FileDelete, winPty_version.html
	URLDownloadToFile, https://github.com/rprichard/winpty/releases/download/%winPty_version%/winpty-%winPty_version%-cygwin-%cygWin_version%-x64.tar.gz, winPty.tar.gz
	
	DownloadLatestTarTool()
	RunWait, TarTool.exe winPty.tar.gz .\,, Hide
	
	winPtyDir = winpty-%winPty_version%-cygwin-%cygWin_version%-x64
	FileCopy, %winPtyDir%\bin\winpty.*, %A_ScriptDir%
	FileCopy, %winPtyDir%\bin\winpty-agent.*, %A_ScriptDir%
	
	FileRemoveDir, %winPtyDir%, 1
	FileDelete, winPty.tar.gz
	FileDelete, TarTool.exe
	FileDelete, ICSharpCode.SharpZipLib.dll
}

DownloadLatestMintty()
{
	URLDownloadToFile, https://github.com/mintty/wsltty/releases/latest, wslTty_version.html
	
	Loop, read, %A_ScriptDir%\wslTty_version.html
	{
		Loop, parse, A_LoopReadLine, %A_Tab%
		{
			If (RegExMatch(A_LoopReadLine, "Release.*[0-9.]+", wslTty_version) > 0)
			{
				foundwslTty = true
				RegExMatch(wslTty_version, "[0-9.]+", wslTty_version)
				break
			}
		}
		If (%foundwslTty% == true)
			break
	}
	
	FileDelete, wslTty_version.html
	
	FileCreateDir, wsltty-%wslTty_version%-x86_64
	SetWorkingDir, wsltty-%wslTty_version%-x86_64
	
	URLDownloadToFile, https://github.com/mintty/wsltty/releases/download/%wslTty_version%/wsltty-%wslTty_version%-x86_64.cab, wslTty.cab
	Unzip("wslTty.cab")
	SetWorkingDir, %A_ScriptDir%

	wslTtyDir = wsltty-%wslTty_version%-x86_64
	FileCopy, %wslTtyDir%\cygwin1.dll, %A_ScriptDir%
	FileCopy, %wslTtyDir%\mintty.exe, %A_ScriptDir%
	
	FileRemoveDir, %wslTtyDir%, 1
	FileDelete, wslTty.cab
}

Unzip(inputZipFile)
{
	inputZipFile = %A_WorkingDir%\%inputZipFile%
	sh := ComObjCreate("Shell.Application")
	sh.Namespace(A_WorkingDir).CopyHere(sh.Namespace(inputZipFile).items, 4|16)
}
