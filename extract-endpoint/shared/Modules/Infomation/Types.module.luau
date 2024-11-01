-- Module
local Types = {}

export type LoopProperties = {
	[string]: any;
}

export type Loop = {
	Properties: LoopProperties;
	Callback: (dt: number, properties: LoopProperties) -> ();
	RemoveCallback: (LoopProperties) -> ();
}

-- Bandit type
export type Bandit = {
	Janitor: {};
	Character: Model;
	Path: Path;
	Animate: {};
	Loops: {Loop};

	-- Movement Properties
	CurrentPathWaypoints: {PathWaypoint}?;
	CurrentDestination: Vector3?;

	-- Memory Properties
	OriginalPosition: CFrame;

	-- Other Janitors
	MoveToJanitor: {};
}

-- Returning
return Types
