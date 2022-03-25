#NoTrayIcon
#NoEnv
#SingleInstance, Force

/* First start setup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Run this on first startup (if no files exist) ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
*/
If (not InStr(FileExist("bin"), "D"))
        FileCreateDir, bin
If (not InStr(FileExist("tmp"), "D"))
        FileCreateDir, tmp
If (not InStr(FileExist("profile"), "D"))
        FileCreateDir, profile

SetWorkingDir, %A_ScriptDir%\bin

If (not FileExist("clink_x64.exe") or not FileExist("clink_dll_x64.dll"))
{
	DownloadLatestClink()
	Sleep, 1000
}

If (not FileExist("cygwin1.dll") or not FileExist("mintty.exe"))
{
	DownloadLatestMintty()
	Sleep, 1000
}

If (not FileExist("winpty.exe") or not FileExist("winpty.dll") or not FileExist("winpty-agent.exe"))
{
	DownloadLatestWinPty()
	Sleep, 1000
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetWorkingDir, %A_ScriptDir%\profile
If not FileExist("mincmd.ini")
{
	FileAppend,
	(
--- Settings ---
registerContextMenu=false


--- Environment ---
首先定义环境变量，然后才能把它们添加到PATH变量中去

cygwinDir=`%HOMEDRIVE`%\Tool\Cygwin\bin
prependPath=
appendPath=`%cygwinDir`%

只要没有等号，任何空行都可以用来做注释！

--- Alias ---
name=bash
type=cmd
----- AliasScript_Start -----
@echo off
"`%cygwinDir`%\bash" --login -i
----- AliasScript_Stop -----
	), mincmd.ini
}

contextMenu = false

SettingsSection = false
EnvSection = false
AliasSection = false
AliasScriptSection = false

Loop, read, mincmd.ini
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
					EnvGet, repStr, % envVar ; 对配置文件中的变量envVar求值，得到环境变量。 repStr := %envVar%，用于内部变量。
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
clinkExe = %A_ScriptDir%\bin\clink_%clink_arch%.exe

EnvGet, cmdExe, ComSpec
gosub, Start
return

!F2::
If (WinActive("ahk_exe bin\mintty.exe ahk_class mintty"))
	gosub, Start
return

Start:
Run, %A_ScriptDir%\bin\mintty.exe -d -c "%A_ScriptDir%\profile\minttyrc" -e "%A_ScriptDir%\bin\winpty.exe" "%cmdExe%" %paramList% /K "%clinkExe%" inject --profile "%A_ScriptDir%\profile" --quiet && title %ComSpec%,,, minPID

while (not WinExist("ahk_exe mintty.exe ahk_class ConsoleWindowClass") and not WinExist("ahk_pid %minPID%"))
	Sleep, 0 ; Do nothing. Just wait for window. Works better than wait for a hidden window to exist

WinHide, ahk_pid %minPID%
SetTimer, checkProcess, 2000
return

checkProcess:
If (not WinExist("ahk_exe bin\mintty.exe ahk_class mintty"))
	ExitApp
return


;;;;;;;;; Needed for first time setup ;;;;;;;;;;

DownloadLatestClink()
{
	SetWorkingDir, %A_ScriptDir%\tmp
	URLDownloadToFile, https://github.com/chrisant996/clink/releases/latest, clink_version.html
	
	Loop, read, clink_version.html
	{
		Loop, parse, A_LoopReadLine, %A_Tab%
		{
			If (RegExMatch(A_LoopReadLine, "clink.[\df.]+.zip", clink_version) > 0)
			{
				
				found = true
				RegExMatch(clink_version, "[\df.]+\d+", clink_version2)
				RegExMatch(clink_version2, "\d+[\d.]+\d+", clink_version1)
				break
			}
		}
		If (%found% == true)
			break
	}
	
	FileDelete, clink_version.html
	URLDownloadToFile, https://github.com/chrisant996/clink/releases/download/v%clink_version1%/clink%clink_version2%.zip, clink.zip
	
	Unzip("clink.zip")
	FileDelete, clink.zip
	
	FileCopy, clink_x*.exe, %A_ScriptDir%\bin
	FileCopy, clink_dll*.dll, %A_ScriptDir%\bin
	FileCopy, clink.lua, %A_ScriptDir%\bin
}

DownloadLatestMintty()
{
	SetWorkingDir, %A_ScriptDir%\tmp
	URLDownloadToFile, https://github.com/mintty/wsltty/releases/latest, wslTty_version.html
	
	Loop, read, wslTty_version.html
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
	
	URLDownloadToFile, https://github.com/mintty/wsltty/releases/download/%wslTty_version%/wsltty-%wslTty_version%-x86_64.cab, wslTty.cab
	Unzip("wslTty.cab")

	FileCopy, cygwin1.dll, %A_ScriptDir%\bin
	FileCopy, mintty.exe, %A_ScriptDir%\bin

	FileCreateDir, %A_ScriptDir%\usr\share\mintty\lang
	FileMove, %A_ScriptDir%\tmp\lang.zoo, %A_ScriptDir%\usr\share\mintty\lang\
	SetWorkingDir, %A_ScriptDir%\usr\share\mintty\lang\
	Run, %A_ScriptDir%\tmp\zoo.exe x lang.zoo,, Hide
	FileDelete, lang.zoo

	FileCreateDir, %A_ScriptDir%\usr\share\mintty\sounds
	FileMove, %A_ScriptDir%\tmp\sounds.zoo, %A_ScriptDir%\usr\share\mintty\sounds\
	SetWorkingDir, %A_ScriptDir%\usr\share\mintty\sounds\
	Run, %A_ScriptDir%\tmp\zoo.exe x sounds.zoo,, Hide
	FileDelete, sounds.zoo

	FileCreateDir, %A_ScriptDir%\usr\share\mintty\themes
	FileMove, %A_ScriptDir%\tmp\themes.zoo, %A_ScriptDir%\usr\share\mintty\themes\
	SetWorkingDir, %A_ScriptDir%\usr\share\mintty\themes\
	Run, %A_ScriptDir%\tmp\zoo.exe x themes.zoo,, Hide
	FileDelete, themes.zoo

	SetWorkingDir, %A_ScriptDir%
}

DownloadLatestWinPty()
{
	SetWorkingDir, %A_ScriptDir%\tmp
	URLDownloadToFile, https://github.com/rprichard/winpty/releases/latest, winPty_version.html
	foundWinPty = false
	foundCygWin = false
	
	Loop, read, %A_ScriptDir%\tmp\winPty_version.html
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
	SetWorkingDir, %A_ScriptDir%\tmp
	RunWait, tarTool.exe winPty.tar.gz .\,, Hide
	
	winPtyDir = %A_WorkingDir%\winpty-%winPty_version%-cygwin-%cygWin_version%-x64
	FileCopy, %winPtyDir%\bin\winpty.*, %A_ScriptDir%\bin
	FileCopy, %winPtyDir%\bin\winpty-agent.*, %A_ScriptDir%\bin
	
	FileRemoveDir, %winPtyDir%, 1
	FileDelete, winPty.tar.gz
	FileDelete, tarTool.exe
	FileDelete, ICSharpCode.SharpZipLib.dll
}

DownloadLatestTarTool()
{
	SetWorkingDir, %A_ScriptDir%\tmp
	URLDownloadToFile, https://github.com/senthilrajasek/tartool/releases/latest, tarTool_version.html
	
	Loop, read, tarTool_version.html
	{
		Loop, parse, A_LoopReadLine, %A_Tab%
		{
			If (RegExMatch(A_LoopReadLine, "/.*TarTool.zip", tarTool_version) > 0)
			{
				found = true
				;RegExMatch(tarTool_version, "[\d.]+", tarTool_version)
				break
			}
		}
		If (%found% == true)
			break
	}
	
	SetWorkingDir, %A_ScriptDir%\tmp
	FileDelete, tarTool_version.html
	URLDownloadToFile, https://github.com%tarTool_version%, tarTool.zip
	SetWorkingDir, %A_ScriptDir%\tmp
	Unzip("tarTool.zip")
	FileDelete, tarTool.zip
}

Unzip(inputZipFile)
{
	inputZipFile = %A_WorkingDir%\%inputZipFile%
	sh := ComObjCreate("Shell.Application")
	sh.Namespace(A_WorkingDir).CopyHere(sh.Namespace(inputZipFile).items, 4|16)
}