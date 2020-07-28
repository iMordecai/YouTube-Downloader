#NoEnv
#KeyHistory 0
ListLines Off
Process, Priority, , A
SetBatchLines, -1
SetKeyDelay, -1, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetWinDelay, -1
SetControlDelay, -1
SendMode Input
SetWorkingDir %A_ScriptDir%

; check if youtube-dl.exe and ffmpeg.exe are present
If !FileExist("youtube-dl.exe")
	MsgBox, 4, YouTube Downloader,You will need to download youtube-dl.exe and save it in the script folder.`n`nDo you want to open the download webpage?
IfMsgBox,Yes 
	Run, http://ytdl-org.github.io/youtube-dl/download.html
If !FileExist("ffmpeg.exe")
	MsgBox, 4, YouTube Downloader,You will also need to download ffmpeg.exe and save it in the script folder.`n`nDo you want to open the download webpage?
IfMsgBox,Yes 
	Run, https://ffmpeg.zeranoe.com/builds/

; GUI
Gui, YT:New
 Gui, Font, s16 Bold, Segoe UI
Gui, Add, Edit, 		Section w580        vLink hwndHED1	,  
 Gui, Font, s12 Normal, Segoe UI
Gui, Add, Checkbox,		Section xs 		vMP3 Checked0	, Audio Only
Gui, Add, Checkbox,		ys x+3	 		vIsPlaylist Checked0 gCheckPlaylist	, Playlist?
 Gui, Add, Text,		ys x+3 			vPlayList		, Playlist Range:
Gui, Add, Edit,			ys-2 x+3 w205 		vRange hwndHED2 Disabled
 Gui, Font, s12 Bold, Segoe UI
Gui, Add, Button, 		ys hp w61		gAddLink		, Add
 Gui, Font, s12 Normal, Segoe UI
Gui, Add, ListView,     	 xs w580 r5 		Grid Checked	, URL|Format|Range|Downloaded
Gui, Add, Button, 		Section xs 		gSelectFolder	, Output Folder
Gui, Add, Text, 		ys+5 x+2 w288		; spacer
Gui, Add, Button,		ys			gClear  vBtnC1	, Clear
Gui, Add, Button,		xp yp Hidden		gReally vBtnC2	, Really?
 Gui, Font, Bold, Segoe UI
Gui, Add, Button, 		ys x+3 			gDownloadLinks	, Download
 Gui, Font, Normal, Segoe UI
Gui, Add, StatusBar, hWndhMySB
SB_SetText("    Select an output folder")
Gui, Show, , YouTube Downloader

SetEditCueBanner(HED1, "Paste YouTube Link")
SetEditCueBanner(HED2, "(Leave empty to download all)")
Return

AddLink:
Gui, YT:Submit,Nohide
If (Link ~= "((http(s)?://)?)(www\.)?((youtube\.com/)|(youtu.be)).+")
	LV_Add(,Link, MP3 ? "Audio" : "Video", IsPlaylist ? ((StrLen(Trim(Range))>0) ? Range : "All") : "", "no")
Loop, 4
	LV_ModifyCol(A_Index, "AutoHdr")
Return

CheckPlaylist:
Gui, YT:Default
Gui, Submit,Nohide
GuiControl, % IsPlaylist ? "Enable" : "Disable", Range
Return

SelectFolder:
FileSelectFolder, SelectedFolder, , 7, Select folder where to download from YouTube
SB_SetTextWithTip(hMySB, "    " SelectedFolder)
Return

Clear:
	Gui, YT:Default
	If (ALRowNumber := LV_GetNext(,"Checked"))
	{
		LV_Delete(ALRowNumber)
		While (ALRowNumber := LV_GetNext(,"Checked"))
			LV_Delete(ALRowNumber)
		Loop, 4
		LV_ModifyCol(A_Index, "AutoHdr")
	} Else {
		GuiControl, Hide,  BtnC1
		GuiControl, Show,  BtnC2
		SetTimer, ShowClearBtn, 3000
	}
Return

ShowClearBtn:
	Gui, YT:Default
	GuiControl, Hide,  BtnC2
	GuiControl, Show,  BtnC1
	Return

Really:
	Gui, YT:Default
	LV_Delete()	; delete all rows 
	Loop, 4
		LV_ModifyCol(A_Index, "AutoHdr")
	Gosub, ShowClearBtn
Return

DownloadLinks:
If !SelectedFolder
{
	MsgBox, , ,Please Select an output folder before downloading, 3
	Return
}

Loop, % LV_GetCount()
{
	LV_GetText(Downloaded,A_Index, 4)
	If (Downloaded == "no")
	{
		LV_GetText(URL		, A_Index, 1)
		LV_GetText(wFormat	, A_Index, 2)
		LV_GetText(Range	, A_Index, 3)
		If (wFormat = "Video")
			If (Range = "All")
				RunWait, youtube-dl.exe --format best --yes-playlist %URL%, %SelectedFolder%,Min
			Else If (Range)
				RunWait, youtube-dl.exe --format best --yes-playlist --playlist-items %Range% %URL%, %SelectedFolder%,Min
			Else
				RunWait, youtube-dl.exe --format best %URL%, %SelectedFolder%,Min
		If (wFormat = "Audio")
			RunWait, youtube-dl.exe --format best -x --audio-format mp3 --yes-playlist %URL%, %SelectedFolder%,Min
		LV_Modify(A_Index,,URL,wFormat,Range,"yes")
	}
}

Return

YTGuiClose:
	ExitApp
	Return

;---FUNCTIONS---------------------------

;====== Set text and tooltip - based on https://www.autohotkey.com/boards/viewtopic.php?t=28706
SB_SetTextWithTip(Handle, Text, Tip := "", Part := 1, Style := 0) 
{
	SB_SetText(Text "                                                                   ", Part, Style)
	Tip := StrReplace((Tip = "") ? Text: Tip , A_Tab, A_Space) ; ToolTip gets messy if it contains tabs
	DllCall("User32.dll\SendMessage", "Ptr", Handle, "UInt", (A_IsUnicode ? 1041 : 1040), "Ptr", Part - 1, "Ptr", &Tip)
}

;======= Creates a cue (placeholder text, hint text) inside an empty edit field
SetEditCueBanner(HWND, Cue) 
{
   Return DllCall("SendMessage", "Ptr", HWND, "Uint", 0x1500 + 1, "Ptr", True, "Str", Cue)
}
