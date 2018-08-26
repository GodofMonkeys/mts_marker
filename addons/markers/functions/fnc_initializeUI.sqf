#include "script_component.hpp"
/**
 *  Author: Timi007
 *
 *  Description:
 *      Opens the interface.
 *      Initializes the UI.
 *      Adds Combobox selections and pictures.
 *
 *  Parameter(s):
 *      0: DISPLAY - Display on which the dialog should apear. (Check mts_markers_fnc_getDisplay)
 *      1: ARRAY - Mouse position on map. (Not needed if parameter 2 is given e.g. nil)
 *      2: STRING - Unique marker prefix for editing set marker. (Not needed if dialog should open with default settings)
 *
 *  Returns:
 *      Nothing.
 *
 *  Example:
 *      [findDisplay 12, [0.5,0.5]] call mts_markers_fnc_initializeUI
 *
 */

params [["_curMapDisplay", displayNull, [displayNull]], ["_mousePos", [0,0], [[]], 2], ["_namePrefix", "", [""]]];

//Open interface
private _displayCheck = _curMapDisplay createDisplay QGVAR(dialog);
CHECKRET(isNull _displayCheck, ERROR("Failed to create dialog"));

private _mainDisplay = findDisplay MAIN_DISPLAY;
private _mapCtrl = _curMapDisplay displayCtrl MAP_CTRL;
CHECK(isNull _mapCtrl);

if (!is3DEN) then {
    //change mouse cursor
    _mapCtrl ctrlMapCursor ["Track", "Arrow"];

    //when display is closed, reset the mouse cursor
    _mainDisplay displayAddEventHandler ["Unload", {
        params ["_mainDisplay"];
        ((displayParent _mainDisplay) displayCtrl MAP_CTRL) ctrlMapCursor ["Track", "Track"];
    }];
};

//combobox controls
private _iconCtrl = _mainDisplay displayCtrl ICON_DROPDOWN;
private _mod1Ctrl = _mainDisplay displayCtrl MOD1_DROPDOWN;
private _mod2Ctrl = _mainDisplay displayCtrl MOD2_DROPDOWN;
private _echelonCtrl = _mainDisplay displayCtrl ECHELON_DROPDOWN;

private _ctrlArray = [
    [_iconCtrl, GVAR(iconArray), "icon"],
    [_mod1Ctrl, GVAR(mod1Array), "mod1"],
    [_mod2Ctrl, GVAR(mod2Array), "mod2"],
    [_echelonCtrl, GVAR(echelonArray), "echelon"]
];

//fill the icon, mod1, mod2 and echelon comboboxes
{
    _x params ["_ctrl", "_dropdownArray", "_arrayPathPrefix"];

    {
        _x params ["_selectionTextSuffix"];

        private _selectionText = format [LSTRING(ui_%1_%2), _arrayPathPrefix, _selectionTextSuffix];
        private _index = _ctrl lbAdd (localize _selectionText);
        _ctrl lbSetValue [_index, _index];

        private _selectionPicturePath = format [QPATHTOF(data\ui\%1\mts_markers_ui_%1_%2.paa), _arrayPathPrefix, _selectionTextSuffix];
        _ctrl lbSetPicture [_index, _selectionPicturePath];
    } count _dropdownArray;

    if !(_ctrl isEqualTo _echelonCtrl) then {
        lbSort _ctrl;
    };
    _ctrl lbSetCurSel 0;
} forEach _ctrlArray;

private _channelCtrl = _mainDisplay displayCtrl CHANNEL_DROPDOWN;
if (!isMultiplayer || is3DEN) then {
    //hide channel dropdown in singleplayer and 3DEN editor
    _channelCtrl ctrlShow false;
    (_mainDisplay displayctrl CHANNEL_TXT) ctrlShow false;
} else {
    //fill the channel combobox & select current channel
    _channelCtrl ctrlShow true;
    (_mainDisplay displayctrl CHANNEL_TXT) ctrlShow true;

    private _channelDropdownArray = [
        ["str_channel_global", 0, "colorGlobalChannel"],
        ["str_channel_side", 1, "colorSideChannel"],
        ["str_channel_command", 2, "colorCommandChannel"],
        ["str_channel_group", 3, "colorGroupChannel"],
        ["str_channel_vehicle", 4, "colorVehicleChannel"],
        ["str_channel_direct", 5, "colorDirectChannel"]
    ];

    {
        _x params ["_selectionText", "_selectionData", "_channelColorData"];

        if ((channelEnabled _selectionData) select 0) then {
            private _selectionColor = (configfile >> "RscChatListMission" >> _channelColorData) call BIS_fnc_colorConfigToRGBA;
            private _index = _channelCtrl lbAdd (localize _selectionText);
            _channelCtrl lbSetValue [_index, _selectionData];
            _channelCtrl lbSetColor [_index, _selectionColor];
        };
    } count _channelDropdownArray;

    if (currentChannel <= 4) then {
        _channelCtrl lbSetCurSel currentChannel;
    } else {
        _channelCtrl lbSetCurSel 5;
    };
};

private _okBtnCtrl = _mainDisplay displayctrl OK_BUTTON;
private _suspectedCbCtrl = _mainDisplay displayCtrl MOD_CHECKBOX;
private _reinforcedCbCtrl = _mainDisplay displayCtrl REINFORCED_CHECKBOX;
private _reducedCbCtrl = _mainDisplay displayCtrl REDUCED_CHECKBOX;

if (_namePrefix isEqualTo "") then {
    //save future marker position
    private _pos = _mapCtrl ctrlMapScreenToWorld [(_mousePos select 0), (_mousePos select 1)];
    _okBtnCtrl setVariable [QGVAR(createMarkerMousePosition), _pos];
    _okBtnCtrl setVariable [QGVAR(editMarkerNamePrefix), ""];

    //select blufor identity as default & update marker preview
    ["blu"] call FUNC(identityButtonsAction);
} else {
    //when editing marker
    //get marker family parameter & information from namespace
    private _markerInformation = GVAR(markerNamespace) getVariable [_namePrefix, [[]]];
    private _markerParameter = _markerInformation select 1;
    CHECK(_markerParameter isEqualTo []);

    private _pos = getMarkerPos (format["%1_frame", _namePrefix]);
    _okBtnCtrl setVariable [QGVAR(createMarkerMousePosition), [(_pos select 0), (_pos select 1)]];
    _okBtnCtrl setVariable [QGVAR(editMarkerNamePrefix), _namePrefix];

    _markerParameter params [
        ["_frameshape", "", [""]],
        ["_dashedFrameshape", false, [false]],
        ["_modifier", [0,0,0], [[]], 3],
        ["_size", [0,false,false], [[]], 3],
        ["_textleft", [], [[]]],
        ["_textright", "", [""]],
        ["_broadcastChannel", 5, [0]]
    ];

    _iconCtrl lbSetCurSel (_modifier select 0);
    _mod1Ctrl lbSetCurSel (_modifier select 1);
    _mod2Ctrl lbSetCurSel (_modifier select 2);

    _echelonCtrl lbSetCurSel (_size select 0);
    _reinforcedCbCtrl cbSetChecked (_size select 1);
    _reducedCbCtrl cbSetChecked (_size select 2);

    (_mainDisplay displayCtrl HIGHER_EDIT) ctrlSetText _textright;
    (_mainDisplay displayCtrl UNIQUE_EDIT) ctrlSetText (_textleft joinString "");

    _channelCtrl lbSetCurSel _broadcastChannel;

    //select right identity in the dialog & update preview
    _suspectedCbCtrl cbSetChecked _dashedFrameshape;
    [_frameshape] call FUNC(identityButtonsAction);
};

//call same ui events that CBA is adding to the map display. Thanks to commy2 for this work-around!
if (_curMapDisplay isEqualTo (findDisplay MAP_PLAYER_DISPLAY)) then {
    _mainDisplay call (uiNamespace getVariable "cba_events_fnc_initDisplayMainMap");
};
if (_curMapDisplay isEqualTo (findDisplay MAP_BRIEFING_DISPLAY)) then {
    _mainDisplay call (uiNamespace getVariable "cba_events_fnc_initDisplayCurator");
};

//add EH for marker preview updating
{
    _x ctrlAddEventHandler ["LBSelChanged", {[false] call FUNC(transmitUIData);}];
} forEach [_iconCtrl, _mod1Ctrl, _mod2Ctrl, _echelonCtrl];

{
    _x ctrlAddEventHandler ["CheckedChanged", {[false] call FUNC(transmitUIData);}];
} forEach [_suspectedCbCtrl, _reinforcedCbCtrl, _reducedCbCtrl];