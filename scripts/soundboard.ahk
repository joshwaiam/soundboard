﻿global sb_gui_state = closed
; category textfield user input
global sb_user_category := ""
; individual file textfield user input
global sb_user_individual := ""
global vlc_pid := ""
global vlc_path := ""
global vlc_audio_out := ""

;----------------------------------------------------
;;;   Sets defaults for GUI
;----------------------------------------------------
sb_gui_autoexecute:
  ; Tomorrow Night Color Definitions:
  cBackground := "c" . "1d1f21"
  cCurrentLine := "c" . "282a2e"
  cSelection := "c" . "373b41"
  cForeground := "c" . "c5c8c6"
  cComment := "c" . "969896"
  cRed := "c" . "cc6666"
  cOrange := "c" . "de935f"
  cYellow := "c" . "f0c674"
  cGreen := "c" . "b5bd68"
  cAqua := "c" . "8abeb7"
  cBlue := "c" . "81a2be"
  cPurple := "c" . "b294bb"
  ; -E0x200 removes border around Edit controls
  gui_control_options := "xm w220 " . cForeground . " -E0x200"
  ; Initialize variable to keep track of the state of the GUI
  sb_gui_state = closed
  return

;----------------------------------------------------
;;;   Creates new instance of soundboard GUI
;----------------------------------------------------
sb_gui_create() {
  if sb_gui_state != closed
  {
    sb_gui_destroy()
    return
  }
  sb_gui_state = open 
  main_gui_destroy()

  ; Tomorrow Night Color Definitions:
  cBackground := "c" . "1d1f21"
  cCurrentLine := "c" . "282a2e"
  cSelection := "c" . "373b41"
  cForeground := "c" . "c5c8c6"
  cComment := "c" . "969896"
  cRed := "c" . "cc6666"
  cOrange := "c" . "de935f"
  cYellow := "c" . "f0c674"
  cGreen := "c" . "b5bd68"
  cAqua := "c" . "8abeb7"
  cBlue := "c" . "81a2be"
  cPurple := "c" . "b294bb"
  ; -E0x200 removes border around Edit controls
  gui_control_options := "xm w520 " . cForeground . " -E0x500"

  Gui, Margin, 16, 16
  Gui, Color, 1d1f21, 282a2e
  Gui, +AlwaysOnTop -SysMenu +ToolWindow -caption +Border
  
  ; Add random categories listview

  Gui, Font, s11, Segoe UI
  Gui, Add, Text, %gui_control_options%, Random Sound From Category
  Gui, Font, s10, Segoe UI
  Gui, Add, Edit, %gui_control_options% vsb_user_category gsb_handle_category_textfield
  Gui, Add, ListView, %gui_control_options% AltSubmit gsb_handle_category_listview, Category

  categories := sb_get_all_categories()
  ; Add each file to the listview
  For index, category in categories
  {

    LV_Add("", category)
  }
  ; Autosize columns
  LV_ModifyCol() 

  ; Add individual items listview

  Gui, Font, s11, Segoe UI
  Gui, Add, Text, %gui_control_options%, Specific Sound
  Gui, Font, s10, Segoe UI
  Gui, Add, Edit, %gui_control_options% vsb_user_individual gsb_handle_individual_textfield
  Gui, Add, ListView, %gui_control_options% AltSubmit h300 gsb_handle_individual_listview, Name | Categories | File Name

  files := sb_get_files()
  ; Add each file to the listview
  For index, file in files
  {
    ; remove categories from file name
    file_name_split := StrSplit(file, "[")
    file_name_string := file_name_split[1]
    ; get all categories for current file
    file_categories := sb_get_file_categories(file)
    ; Convert file_categories array into a string
    file_categories_string := ""
    For index2, file_category in file_categories
    {
      file_categories_string .= ", " . file_category
    }
    ; Purge leading comma from string
    file_categories_string := StrReplace(file_categories_string, ",","",, Limit := 1)
    ; Purge ] from string
    file_categories_string := StrReplace(file_categories_string, "]","")
    ; Add row to listview
    LV_Add("", file_name_string, file_categories_string, file)
  }
  ; Autosize each column
  LV_ModifyCol()

  Gui, Show,, sbGUI
}
;----------------------------------------------------
;;;   SDestroys the soundboard GUI
;----------------------------------------------------
#WinActivateForce
sb_gui_destroy() {
  sb_gui_state = closed
  ; Hide GUI
  Gui, Destroy
  ; Remove tooltip
  ToolTip
  ; Bring focus back to another window found on the desktop
  WinActivate
}

;----------------------------------------------------
;;;   Handles the textbox for sound categories
;----------------------------------------------------
sb_handle_category_textfield() {
  Gui, Submit, NoHide

  ; Set focus on correct listview
  Gui, ListView, SysListView321

  matched_categories := []
  categories := sb_get_all_categories()
  For index, category in categories
  {
    if !InStr(category, sb_user_category)
    {
      continue
    }
    matched_categories.push(category)
  }

  ; Remove all items
  LV_Delete()
  ; Add matched items only
  For index, category in matched_categories
  {
    LV_Add("", category)
  }
  ; Autosize columns
  LV_ModifyCol()

  if matched_categories.Length() = 1
  {
    LV_GetText(RowText, 1)
    sb_play_random_sound(RowText)
  }
}

;----------------------------------------------------
;;;   Handles the listview for sound categories
;----------------------------------------------------
sb_handle_category_listview() {
  ; Force LV commands to use the appropriate listview
  Gui, ListView, SysListView321
  if (A_GuiEvent = "DoubleClick")
  {
    LV_GetText(RowText, A_EventInfo)
    sb_play_random_sound(RowText)
    return
  }
}

;----------------------------------------------------
;;;   Handles the textfield for the individual sounds
;----------------------------------------------------
sb_handle_individual_textfield() {
  Gui, Submit, NoHide

  ; Set focus on correct listview
  Gui, ListView, SysListView322

  matched_files := []
  files := sb_get_files()
  For index, file in files
  {
    if !InStr(file, sb_user_individual)
    {
      continue
    }
    matched_files.push(file)
  }

  ; Remove all items
  LV_Delete()
  ; Add matched items only
  For index, file in matched_files
  {
    ; remove categories from file name
    file_name_split := StrSplit(file, "[")
    file_name_string := file_name_split[1]
    ; get all categories for current file
    file_categories := sb_get_file_categories(file)
    ; Convert file_categories array into a string
    file_categories_string := ""
    For index2, file_category in file_categories  
    {
      file_categories_string .= ", " . file_category
    }
    ; Purge leading comma from string
    file_categories_string := StrReplace(file_categories_string, ",","",, Limit := 1)
    ; Purge ] from string
    file_categories_string := StrReplace(file_categories_string, "]","")
    ; Add row to listview
    LV_Add("", file_name_string, file_categories_string, file)
  }
  ; Autosize columns
  LV_ModifyCol()

  if matched_files.Length() = 1
  {
    LV_GetText(RowText, 1, 3)
    ToolTip %RowText%
    sb_play_sound(A_ScriptDir . "\sounds\" . RowText . ".mp3")
    return
  }
}

;----------------------------------------------------
;;;   Handles the listview for the individual sounds
;----------------------------------------------------
sb_handle_individual_listview() {
  Gui, ListView, SysListView322
  if (A_GuiEvent = "DoubleClick")
  {
    LV_GetText(RowText, A_EventInfo, 3)
    sb_play_sound(A_ScriptDir . "\sounds\" . RowText . ".mp3")
  }
}

;----------------------------------------------------
;;;   Returns a list of all mp3 files in /sounds folder
;----------------------------------------------------
sb_get_files() {
  local sounds := {}
  Loop Files, sounds\*.mp3 
  {
    sounds.push(StrReplace(A_LoopFileName, ".mp3", ""))
  }

  return unique(sounds)
}

;----------------------------------------------------
;;;   Returns a list of all folders in /sounds
;----------------------------------------------------
sb_get_all_categories() {
  local categories := []
  Loop Files, sounds\*.mp3 
  {
    file_categories := sb_get_file_categories(A_LoopFileName)
    if(file_categories.Length() = 0) 
    {
      continue
    }
    For i, category In file_categories 
    {
      categories.push(category)
    }
  }
  return unique(categories)
}

;----------------------------------------------------
;;;   Parses categories from a provided file_name
;;;
;;;     * Categories are enclosed in [] and separated by commas in file_name
;;;     * Categories should come at the end of the file name.
;;;     ex. big moustache [naked gun, random].mp3
;----------------------------------------------------
sb_get_file_categories(file_name) {
  local categories := []
  local file_categories := StrSplit(file_name, "[")
  if(file_categories.Length() <= 1) 
  {
    return ""
  }
  split_categories := StrSplit(file_categories[2], ",")
  if(split_categories.Length() = 0) 
  {
    return ""
  }
  For i, category in split_categories 
  {
    category := Trim(StrReplace(category, "].mp3", ""))
    categories.push(category)
  }
  return categories
}

;----------------------------------------------------
;;;   Plays a random sound from a provided category
;----------------------------------------------------
sb_play_random_sound(requested_category) {
  files := []
  ; Get a list of all files in the category folder
  Loop Files, sounds\*.mp3 
  {
    file_categories := sb_get_file_categories(A_LoopFileName)
    For i, category In file_categories 
    {
      if (category = requested_category) 
      {
        files.push(A_LoopFileName)
      }
    }
  }
  if(files.length() = 0) 
  {
    return
  }
  ; If there is only one file for the category, just play it
  if(files.length() = 1) 
  {
    randomIndex := 1
  } 
  ; Pick a random file index and store in randomIndex
  else 
  {  
    Random, randomIndex, 1, files.length()
  }
  if(files[randomIndex] != "") 
  {
    file_path := A_ScriptDir . "\sounds\" . files[randomIndex]
    sb_play_sound(file_path)
  }
}

;----------------------------------------------------
;;;   Plays sound provided by file_path
;----------------------------------------------------
sb_play_sound(file_path) {
  vlc_path := "C:\Program Files\VideoLAN\VLC\vlc.exe"
  vlc_audio_out := "Music (VB-Audio Cable A) ($1,$64)"
  if !FileExist(file_path) 
  {
    return
  }
  sb_stop_sound()
  Run "%vlc_path%" --aout=waveout --waveout-audio-device="%vlc_audio_out%" --play-and-exit --qt-start-minimized --qt-system-tray "%file_path%",,,vlc_pid
  sb_gui_destroy()
}

;----------------------------------------------------
;;;   Stops the currently playing sound
;----------------------------------------------------
sb_stop_sound() {
  Process, Close, %vlc_pid%
  sb_gui_destroy()
}