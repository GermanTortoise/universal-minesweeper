--!strict

local Types = {}

export type GameControllerImpl = {
	__index: GameControllerImpl,
	new: (shape: { number }, boardPos: Vector3) -> (),
	Activate: (self: GameController, tilesRevealed: { { number } }) -> (),
	ToggleFlag: (self: GameController, textPart: number, flagged: boolean) -> (),
}

export type GameController = typeof(setmetatable(
	{} :: {
		TextParts: { TextPart },
	},
	{} :: GameControllerImpl
))

export type TextPartImpl = {
	__index: TextPartImpl,
	new: (size: Vector3, location: CFrame, idx: number) -> TextPart,
	RegisterClick: (self: TextPart, leftClickCallBack: () -> (), rightClickCallBack: () -> ()) -> (),
	UnregisterClick: (self: TextPart) -> (),
	Destroy: (self: TextPart) -> (),
	Reveal: (self: TextPart, revealMines: boolean, val: number) -> (),
	ToggleFlag: (self: TextPart, flagged: boolean) -> (),
	-- SetHighlight: (self: Tile, status: boolean) -> (),
	_activate: (self: TextPart) -> (),
	_chord: (self: TextPart) -> (),
	_canHide: (self: TextPart) -> boolean,
	_toggleHiddenTiles: (self: TextPart) -> (),
	_show: (self: TextPart) -> (),
	_hide: (self: TextPart) -> (),
	_hasCorrectNumberFlags: (self: TextPart) -> boolean,
}

export type TextPart = typeof(setmetatable(
	{} :: {
		Part: Part,
		Label: TextLabel,
		Idx: number,
		Val: number?,
		Activated: boolean,
		Flagged: boolean,
		NearbyTiles: { TextPart },
	},
	{} :: TextPartImpl
))

export type TileImpl = {
	__index: TileImpl,
	new: (val: number, idx: number) -> Tile,
	ToggleFlag: (self: Tile) -> (),
	HasCorrectNumberFlags: (self: Tile) -> (),
}

export type Tile = typeof(setmetatable(
	{} :: {
		Activated: boolean,
		Flagged: boolean,
		NearbyTiles: { Tile },
		Value: number,
		Idx: number,
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
	ListenClicks: (self: Board) -> (),
	CheckVictory: (self: Board) -> (),
	LeftClick: (self: Board, idx: number) -> (),
	_chord: (self: Board, idx: number) -> (),
	ActivateTile: (self: Board, tile: Tile) -> (),
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
		FlagsCount: number,
		Tiles: { Tile },
		totalNumTiles: number,
		Move: { { number } },
		-- Resetter: TextPart,
		-- MinesCounter: TextPart,
		NumberBoard: { number },
	},
	{} :: BoardImpl
))

return Types
