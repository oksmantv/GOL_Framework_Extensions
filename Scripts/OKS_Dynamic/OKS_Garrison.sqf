	// OKS_Garrison
	if(HasInterface && !isServer) exitWith {};

	Params ["_NumberInfantry","_House","_Side","_Units"];
	Private ["_GarrisonPositions","_GarrisonMaxSize","_GarrisonMaxSize","_Unit"];

	_GarrisonPositions = [_House] call BIS_fnc_buildingPositions;
	_GarrisonMaxSize = count _GarrisonPositions;

	if(_NumberInfantry > _GarrisonMaxSize) then {
		_NumberInfantry = _GarrisonMaxSize;
		_Group = CreateGroup _Side;
		{
			if ( (count (units _Group)) == 0 ) then
			{
				_Unit = _Group CreateUnit [(_Units call BIS_FNC_selectRandom), _X, [], 0, "NONE"];
				_Unit setRank "SERGEANT";
			} else {
				_Unit = _Group CreateUnit [(_Units call BIS_FNC_selectRandom), _X, [], 0, "NONE"];
				_Unit setRank "PRIVATE";
			};
			_Unit setRank "PRIVATE";
			_Unit disableAI "PATH";
			_Unit setUnitPosWeak "UP";
		} foreach _GarrisonPositions;
	} else {

		_Group = CreateGroup _Side;
		for "_i" from 1 to _NumberInfantry do
		{
			Private "_Unit";
			if ( (count (units _Group)) == 0 ) then
			{
				_Unit = _Group CreateUnit [(_Units call BIS_FNC_selectRandom), [0,0,0], [], 0, "NONE"];
				_Unit setRank "SERGEANT";
			} else {
				_Unit = _Group CreateUnit [(_Units call BIS_FNC_selectRandom), [0,0,0], [], 0, "NONE"];
				_Unit setRank "PRIVATE";
			};
			_Unit disableAI "PATH";
			_Unit setUnitPosWeak "UP";
			sleep 0.5;
		};

		{
			_position = (selectRandom _GarrisonPositions);
			_GarrisonPositions deleteAt (_GarrisonPositions find _position);
			_X setPos _position;
			_X setDir (Random 360);
		} foreach units _Group;

		 /* Arguments:
			 * 0: The building(s) nearest this position are used <POSITION>
			 * 1: Limit the building search to those type of building <ARRAY>
			 * 2: Units that will be garrisoned <ARRAY>
			 * 3: Radius to fill building(s) <SCALAR> (default: 50)
			 * 4: 0: even filling, 1: building by building, 2: random filling <SCALAR> (default: 0)
			 * 5: True to fill building(s) from top to bottom <BOOL> (default: false) (note: only works with filling mode 0 and 1)
			 * 6: Teleport units <BOOL> (default: false)
		 */
		[getPos (leader _Group), nil, units _Group, 5, 1, true, true] remoteExec  ["ace_ai_fnc_garrison",0];
	};
