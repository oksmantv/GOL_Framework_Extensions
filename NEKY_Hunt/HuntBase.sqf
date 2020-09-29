

//////// Created by Oksman ////////////////////////////////////////////////////////////////////////////////////
///
///		Parameters:
///     Object - If this object is destroyed the camp will no longer spawn attacks, use something that can be destroyed such as trucks, tents, buildings etc.
///
///		SpawnObject - Set down a Helipad (Invisible) and face the direction you want the vehicle/group to spawn in
///
///		Trigger - Set up a trigger used to define the hunting space for these reinforcements, set it to Any Players and repeatable for best effect.
///
///		Number of Waves - Select number of waves using a SCALAR value (0-999)
///
///		Respawn Delay - Select in seconds how long between spawns and respawns of waves
///
///		Side - The side of the faction you wanted spawned
///
///		Soldiers or Classname - SCALAR or ARRAY - If you select numbers there will be X amount of soldiers in 1 group. If you input a string Example: "CUP_O_BTR40_MG_TKM" you will get this vehicle crewed by the faction the vehicle is ///     based on. If you want to have a randomly selected vehicle you can input an Array with strings, example: ["CUP_O_MTLB_pk_TK_MILITIA","CUP_O_BTR40_MG_TKM","CUP_O_Ural_ZU23_TKM","CUP_O_BTR90_RU"]
///
///		Refresh Rate - Time in seconds you want the script to refresh their knowledge of Players inside the hunt zone, quickens the response with shorter refresh, but increases slightly in the performance cost.
///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//		[Object, Spawn, Trigger, 10,300,EAST,6,30] spawn NEKY_Hunt_HuntBase;
//		[Object, Spawn, Trigger, 10,450,EAST,"CUP_O_BTR40_MG_TKM",30] spawn NEKY_Hunt_HuntBase;
//		[Object, Spawn, Trigger, 10,450,EAST,["CUP_O_MTLB_pk_TK_MILITIA","CUP_O_BTR40_MG_TKM","CUP_O_Ural_ZU23_TKM","CUP_O_BTR90_RU"],30] spawn NEKY_Hunt_HuntBase;
//
//		Best Activated in SpawnList for resource saving.
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

if (!isServer) exitWith {false};	// Ensures only server

Params["_Base","_SpawnPos","_HuntZone","_Waves","_RespawnDelay","_Side","_Soldiers","_RefreshRate"];




Params
[
	["_Base", ObjNull, [ObjNull]],
	["_SpawnPos", ObjNull, [ObjNull]],
	["_HuntZone", ObjNull, [ObjNull]],
	["_Waves", 0, [0]],
	["_RespawnDelay", 0, [0]],
	["_Side", East, [sideUnknown]],
	["_Soldiers", 0, ["",0,[]]],
	["_RefreshRate", 0, [0]]
];

Private ["_Leaders","_Units","_Vehicle","_VehicleClass","_MaxCargoSeats","_Trigger"];

sleep 5;

_Settings = [] Call NEKY_Hunt_Settings;
_Settings Params ["_MinDistance","_UpdateFreqSettings","_SkillVariables","_Skill","_Leaders","_Units","_MaxCargoSeats"];

	_Trigger = createTrigger ["EmptyDetector", getPosWorld _SpawnPos, false];
	_Trigger setTriggerActivation ["ANYPLAYER", "PRESENT", true];
	_Trigger setTriggerArea [300, 300, 0, false];

	_EyeCheck = createVehicle ["Sign_Sphere25cm_F", [getPos _SpawnPos select 0,getPos _SpawnPos select 1,(getPos _SpawnPos select 2) + 3], [], 0, "CAN_COLLIDE"];
	_EyeCheck hideObject true;
	_EyeCheck enableSimulation false;


while {alive _Base && _Waves > 0} do
{
	//SystemChat "Inside Base & Waves";
	//SystemChat Str [_Side,({isTouchingGround (vehicle _X) && (isPlayer _X)} count list _HuntZone > 0)];

	if( {(_Side knowsAbout _X > 3.5 || _Side knowsAbout vehicle _X > 3.5) && isTouchingGround (vehicle _X) && (isPlayer _X)} count list _HuntZone > 0) then {

		//SystemChat "Inside Trigger.. Waiting";
		sleep (Random 120);

		SystemChat str [({isTouchingGround (vehicle _X) && (isPlayer _X) && [objNull, "VIEW"] checkVisibility [eyePos _X, getPosASL _EyeCheck] >= 0.6} count AllPlayers < 1),({isTouchingGround (vehicle _X) && (isPlayer _X)} count list _Trigger < 1)];

		if( {isTouchingGround (vehicle _X) && (isPlayer _X) && [objNull, "VIEW"] checkVisibility [eyePos _X, getPosASL _EyeCheck] >= 0.6} count AllPlayers > 0 || {isTouchingGround (vehicle _X) && (isPlayer _X)} count list _Trigger > 0 ) then {
			SystemChat "Spawn in View or Inside Safe Trigger..";
		}
		else
		{
			_Waves = _Waves - 1;
			if(typeName _Soldiers == "SCALAR") then
			{
				_Group = CreateGroup _Side;
				for "_i" from 1 to _Soldiers do
				{
					Private "_Unit";
					if ( (count (units _Group)) == 0 ) then
					{
						_Unit = _Group CreateUnit [(_Units call BIS_FNC_selectRandom), _SpawnPos, [], 0, "NONE"];
						_Unit setRank "SERGEANT";
					} else {
						_Unit = _Group CreateUnit [(_Units call BIS_FNC_selectRandom), _SpawnPos, [], 0, "NONE"];
						_Unit setRank "PRIVATE";

					};
				};

				///SystemChat str [_Skill,_SkillVariables,_Group];
				[_Group, _SkillVariables, _Skill] Spawn NEKY_Hunt_SetSkill;
				_Group AllowFleeing 0;

				sleep 1;
				[_Group, nil, _HuntZone, 0, 30, 0, {}] Spawn NEKY_Hunt_Run;
				SystemChat "Infantry Spawned...";

			};

			if(typeName _Soldiers == "STRING" || typeName _Soldiers == "ARRAY") then {

				if(typeName _Soldiers == "ARRAY") then {
					_VehicleClass = _Soldiers call BIS_fnc_selectRandom;
					_Vehicle = CreateVehicle [_VehicleClass, _SpawnPos, [], 0, "CAN_COLLIDE"];
				}
				else
				{
					_Vehicle = CreateVehicle [_Soldiers, _SpawnPos, [], 0, "CAN_COLLIDE"];
				};

				_Vehicle setDir getDir _SpawnPos;
				createVehicleCrew _Vehicle;

				sleep 2;

				if(Count (TypeOf _Vehicle call BIS_fnc_AllTurrets) == 0) then {

					_Group = group (driver _Vehicle);
					_CargoSeats = ([TypeOf _Vehicle,true] call BIS_fnc_crewCount) - (["TypeOf _Vehicle",false] call BIS_fnc_crewCount);
					if(_CargoSeats > _MaxCargoSeats) then { _CargoSeats = _MaxCargoSeats };

						/// Create Leader
						_Unit = _Group CreateUnit [(_Units call BIS_FNC_selectRandom), [0,0,50], [], 0, "NONE"];
						_Unit setRank "SERGEANT";
						_Unit MoveInCargo _Vehicle;
						_Group selectLeader _Unit;

					for "_i" from 1 to (_CargoSeats - 1) do
					{
						Private "_Unit";
						_Unit = _Group CreateUnit [(_Units call BIS_FNC_selectRandom), [0,0,50], [], 0, "NONE"];
						_Unit setRank "PRIVATE";
						_Unit MoveInCargo _Vehicle;
					};

					///SystemChat str [_Skill,_SkillVariables,_Group];
					[_Group, _SkillVariables, _Skill] Spawn NEKY_Hunt_SetSkill;
					_Group AllowFleeing 0;

				};

				SystemChat "Vehicle Spawned...";
				sleep 1;
				[Group (Driver _Vehicle), nil, _HuntZone, 0, 30, 0, {}] Spawn NEKY_Hunt_Run;

			};

			sleep _RespawnDelay;
		};
	}
	else
	{
		sleep _RefreshRate;
	};

};

if(!alive _Base) exitWith { SystemChat "Base Destroyed - Exiting Script"};
if(_Waves == 0) exitWith { SystemChat "Waves Depleted - Exiting Script"};

/*
	Params ["_Side","_Number","_Leaders","_Units","_Pos"];

	_Grp = CreateGroup _Side;
	_Leader = _Grp CreateUnit [(selectRandom _Leaders), [0,0,0], [], 10, "NONE"];
	_Leader SetRank "Sergeant";
	_Pos = getPos _SpawnPos;
	_Leader setPos _Pos;

	For "_i" from 2 to _Number step 1 do
	{
		_Unit = _Grp createUnit [(SelectRandom _Units), _Leader, [], 10, "NONE"];
		_Unit setRank "PRIVATE";
	};

*/


