; vJoy Template for ADHD
; An example script to show how to build a virtual joystick app with ADHD

; Uses Shaul's vJoy - http://http://vjoystick.sourceforge.net/site/ - install this first
; Then you need the AHK vJoy library - grab the VJoyLib folder from my UJR project: 
; https://github.com/evilC/AHK-Universal-Joystick-Remapper/tree/master/VJoyLib
; And place it in your AutoHotkey Lib folder (C:\Program Files\Autohotkey\Lib)
; So you end up with a C:\Program Files\Autohotkey\Lib\VjoyLib folder.
; (The vJoyLib folder is also packaged in the UJR release zip) - http://evilc.com/proj/ujr

; Create an instance of the library
ADHD := New ADHDLib

ADHD.run_as_admin()

; ============================================================================================
; CONFIG SECTION - Configure ADHD

; Authors - Edit this section to configure ADHD according to your macro.
; You should not add extra things here (except add more records to hotkey_list etc)
; Also you should generally not delete things here - set them to a different value instead

; You may need to edit these depending on game
SendMode, Event
SetKeyDelay, 0, 50

; Stuff for the About box

ADHD.config_about({name: "MWO Relative Throttle", version: 0.3, author: "evilC", link: "<a href=""http://evilc.com/proj/adhd"">Homepage</a>"})
; The default application to limit hotkeys to.

; GUI size
ADHD.config_size(375,220)

; We need no actions, so disable warning
ADHD.config_ignore_noaction_warning()
ADHD.config_ignore_x64_warning()

; Hook into ADHD events
; First parameter is name of event to hook into, second parameter is a function name to launch on that event
ADHD.config_event("app_active", "app_active_hook")
ADHD.config_event("app_inactive", "app_inactive_hook")
ADHD.config_event("option_changed", "option_changed_hook")

ADHD.config_hotkey_add({uiname: "Bind Axis To Game", subroutine: "BindAxis", tooltip: "Hotkey to bind axis in game"})
ADHD.config_hotkey_add({uiname: "Stop", subroutine: "Stop", tooltip: "Center the throttle"})

ADHD.init()
ADHD.create_gui()

; The "Main" tab is tab 1
Gui, Tab, 1
; ============================================================================================
; GUI SECTION

axis_list_ahk := Array("X","Y","Z","R","U","V")

Gui, Add, GroupBox, x5 yp+25 W365 R3 section, Input Configuration
Gui, Add, Text, x15 ys+20, Joystick ID
ADHD.gui_add("DropDownList", "JoyID", "xp+80 yp-5 W50", "1|2|3|4|5|6|7|8", "1")
JoyID_TT := "The ID (Order in Windows Game Controllers?) of your Joystick"

Gui, Add, Text, xp+80 ys+20, Axis
ADHD.gui_add("DropDownList", "JoyAxis", "xp+40 yp-5 W50", "1|2|3|4|5|6", "1")
JoyAxis_TT := "The Axis on that stick that you wish to use"

ADHD.gui_add("CheckBox", "InvertAxis", "xp+80  yp+5", "Invert Axis", 0)
InvertAxis_TT := "Inverts the input axis.`nNot intended to be used with ""Use Half Axis"""

Gui, Add, Text, x15 ys+50, Deadzone `%
ADHD.gui_add("Edit", "DeadzoneAmount", "xp+80 yp-5 W50", "", 10)
DeadzoneAmount_TT := "The amount of Dead Zone to apply to the axis"

Gui, Add, Text, xp+80 ys+50, Change Factor
ADHD.gui_add("Edit", "ChangeFactor", "xp+80 yp-5 W50", "", 0.1)
ChangeFactor_TT := "The rate at which to accelerate / decelerate"

Gui, Add, GroupBox, x5 yp+35 R2 W365 section, Debugging
Gui, Add, Text, x15 ys+15, Input axis value
Gui, Add, Edit, xp+120 yp-2 W50 R1 vAxisValueIn ReadOnly,
AxisValueIn_TT := "Raw input value of the axis.`nIf you have Joystick ID and axis set correctly,`nmoving the axis should change the numbers here"

Gui, Add, Text, xp+60 ys+15, Adjusted axis value
Gui, Add, Edit, xp+100 yp-2 W50 R1 vAxisValueOut ReadOnly,
AxisValueOut_TT := "Input value adjusted according to options`nShould be 0 at center, 100 at full deflection"

; End GUI creation section
; ============================================================================================


axis_list_ahk := Array("X","Y","Z","R","U","V")

; Start vJoy setup
axis_list_vjoy := Array("X","Y","Z","RX","RY","RZ","SL0","SL1")

;#include VJoyLib\VJoy_lib.ahk
#include VJoy_lib.ahk
LoadPackagedLibrary() {
	SplitPath, A_AhkPath,,tmp
    if (A_PtrSize < 8) {
        dllpath := tmp "\Lib\VJoyLib\x86\vJoyInterface.dll"
    } else {
        dllpath := tmp "\Lib\VJoyLib\x64\vJoyInterface.dll"
    }
    hDLL := DLLCall("LoadLibrary", "Str", dllpath)
    if (!hDLL) {
        MsgBox, [%A_ThisFunc%] Failed to find DLL at %dllpath%
    }
    return hDLL
}
; Load DLL
LoadPackagedLibrary()

; ID of the virtual stick (1st virtual stick is 1)
vjoy_id := 1

; Init Vjoy library
VJoy_Init(vjoy_id)
; End vjoy setup

ADHD.finish_startup()

; Loop runs endlessly...
axis := 0
old_axis := 0
 
Loop, {
	; Get the value of the axis the user has selected as input
	axis_in := conform_axis()

	; convert axis from input range of 0 -> 100 to -50 -> +50
	axis_in := axis_in - 50

	; Update the contents of the "Current" debugging text box
	GuiControl,,AxisValueIn, % round(axis_in,1)
	
	if (abs(axis_in) > DeadzoneAmount){
		; Stick deflected, modify old axis value by new axis value
		axis := old_axis + (axis_in * ChangeFactor)
	} else {
		; Stick at neutral - do nothing
		axis := old_axis
		axis_in := 0
	}

	; Make sure axis stays within valid range	 
	if (axis > 50){
		axis := 50
	} else if (axis < -50){
		axis := -50
	}

	; Save axis state for next loop, so we can increment or decrement it.
	old_axis := axis

	; Revert axis back to 0 -> 100 scale
	axis += 50

	; Update the contents of the "Adjusted" text box
	GuiControl,,AxisValueOut, % round(axis_in,1)
	 	 
	; Assemble the string which sets which virtual axis will be manipulated
	vjaxis := axis_list_vjoy[2]
	 
	; input is in range 0->100, but vjoy operates in 0->32767, so convert to correct output format
	axis := axis * 327.67
	 
	; Set the vjoy axis
	VJoy_SetAxis(axis, vjoy_id, HID_USAGE_%vjaxis%)
	 
	 
	; Sleep a bit to chew up less CPU time
	Sleep, 10
	 
}
return
; Conform the input value from an axis to a range between 0 and 100
; Handles invert, half axis usage (eg xbox left trigger) etc
conform_axis(){
	global axis_list_ahk
	global JoyID
	global JoyAxis
	global InvertAxis
	
	; Assemble string to describe which axis the user selected (eg 2JoyX)
	tmp := JoyID "Joy" axis_list_ahk[JoyAxis]
	
	; Detect the state of the input axis
	GetKeyState, axis, % tmp
	
	; Invert the axis if the user selected the option
	if (InvertAxis){
		axis := 100 - axis
	}
	
	return axis
}

BindAxis:
	; Assemble the string which sets which virtual axis will be manipulated
	vjaxis := axis_list_vjoy[2]
	 
	; Set the vjoy axis to middle
	VJoy_SetAxis(16384, vjoy_id, HID_USAGE_%vjaxis%)	

	Sleep 1000

	SoundBeep

	; Fully deflect axis
	VJoy_SetAxis(0, vjoy_id, HID_USAGE_%vjaxis%)	

	Sleep 500

	; Set the vjoy axis to middle
	VJoy_SetAxis(16384, vjoy_id, HID_USAGE_%vjaxis%)	
	Return

Stop:
	old_axis := 0
	Return

app_active_hook(){

}

app_inactive_hook(){

}

option_changed_hook(){
	global ADHD

}

; KEEP THIS AT THE END!!
#Include ADHDLib.ahk		; If you have the library in the same folder as your macro, use this
;#Include <ADHDLib>			; If you have the library in the Lib folder (C:\Program Files\Autohotkey\Lib), use this
