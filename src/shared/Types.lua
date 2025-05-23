--!strict

local Types = {}

export type TextPartImpl = {
	__index: TextPartImpl,
	new: (size: Vector3, location: CFrame) -> TextPart,
	RegisterClick: (self: TextPart, leftClickCallBack: () -> (), rightClickCallBack: () -> (), nearby: { Tile }?) -> (),
	UnregisterClick: (self: TextPart) -> (),
	Destroy: (self: TextPart) -> (),
}

export type TextPart = typeof(setmetatable({} :: { Part: Part, Label: TextLabel }, {} :: TextPartImpl))

export type TileImpl = {
	__index: TileImpl,
	new: () -> Tile,
}

export type Tile = typeof(setmetatable(
	{} :: {
		Activated: boolean,
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
