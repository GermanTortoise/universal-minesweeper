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
	new: (board: Board, value: number, arr: { number }) -> Tile,
	Activate: (self: Tile) -> (),
	Reveal: (self: Tile) -> (),
	ToggleFlag: (self: Tile) -> (),
}

export type Tile = typeof(setmetatable(
	{} :: { TextPart: TextPart, Activated: boolean, Board: Board, Value: number, Idx: { number }, Flagged: boolean },
	{} :: TileImpl
))

export type MineImpl = {
	__index: MineImpl,
	new: (board: Board, idx: { number }) -> Mine,
	Reveal: (self: Mine) -> (),
	ToggleFlag: (self: Mine) -> (),
}

export type Mine = typeof(setmetatable(
	{} :: { TextPart: TextPart, Flagged: boolean, Board: Board, Idx: { number } },
	{} :: MineImpl
))

export type BoardImpl = {
	__index: BoardImpl,
	new: (shape: { number }, numMines: number, position: Vector3) -> Board,
	PrepareBoard: (self: Board) -> (),
	ResetGame: (self: Board) -> (),
	EndGame: (self: Board, revealMines: boolean?) -> (),
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
		CorrectlyFlaggedMines: number,
		FlagsCount: number,
		Tiles: { Tile | Mine },
		totalNumTiles: number,
		Resetter: TextPart,
		MinesCounter: TextPart,
		NumberBoard: { number },
	},
	{} :: BoardImpl
))

return Types
