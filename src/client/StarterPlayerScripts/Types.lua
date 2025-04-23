--!strict

local Types = {}

export type TextPartImpl = {
	__index: TextPartImpl,
	new: (size: Vector3, location: CFrame) -> TextPart,
	RegisterClick: (self: TextPart, leftClickCallBack: () -> (), rightClickCallBack: () -> ()) -> (),
	UnregisterClick: (self: TextPart) -> (),
	Destroy: (self: TextPart) -> (),
}

export type TextPart = typeof(setmetatable({} :: { Part: Part, Label: TextLabel }, {} :: TextPartImpl))

export type TileImpl = {
	__index: TileImpl,
	new: (board: Board, value: number, nDIdx: { number }) -> Tile,
	LeftClick: (self: Tile) -> (),
	InitNearbyTiles: (self: Tile) -> (),
	Reveal: (self: Tile, revealMines: boolean?) -> (),
	ToggleFlag: (self: Tile) -> boolean,
	_activate: (self: Tile) -> (),
	_chord: (self: Tile) -> (),
	_canHide: (self: Tile) -> boolean,
	_toggleHiddenTiles: (self: Tile) -> (),
	_show: (self: Tile) -> (),
	_hide: (self: Tile) -> (),
	_hasCorrectNumberFlags: (self: Tile) -> boolean,
}

export type Tile = typeof(setmetatable(
	{} :: {
		TextPart: TextPart,
		Activated: boolean,
		Board: Board,
		Value: number,
		Idx: { number },
		Flagged: boolean,
		NearbyTiles: { Tile },
	},
	{} :: TileImpl
))

export type BoardImpl = {
	__index: BoardImpl,
	new: (shape: { number }, numMines: number, position: Vector3) -> Board,
	PrepareBoard: (self: Board) -> (),
	ResetGame: (self: Board) -> (),
	EndGame: (self: Board, revealMines: boolean) -> (),
	UpdateMinesCounter: (self: Board) -> (),
	CheckVictory: (self: Board) -> (),
}
--[[
blah
]]
export type Board = typeof(setmetatable(
	{} :: {
		Shape: { number },
		Mines: number,
		Position: Vector3,
		GameEnded: boolean,
		-- CorrectlyFlaggedMines: number,
		FlagsCount: number,
		Tiles: { Tile },
		totalNumTiles: number,
		Resetter: TextPart,
		MinesCounter: TextPart,
		NumberBoard: { number },
	},
	{} :: BoardImpl
))

return Types
