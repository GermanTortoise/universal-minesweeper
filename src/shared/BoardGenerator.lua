--!strict

local MSmodule = {}

function MSmodule.placeMines(arr: { number }, numMines: number, mineVal: number): { number }
	-- n unique random ints from 1 to range
	local max = #arr
	if numMines > max then -- check for bad input
		error(string.format("%d random ints out of bounds for range %d", numMines, max))
	end

	local indices = {}
	math.randomseed(os.time())
	for _ = 1, numMines do
		local try = math.random(1, max)
		while arr[try] == mineVal do
			try = math.random(1, max)
		end
		arr[try] = mineVal
		table.insert(indices, try)
	end
	return indices
end

function MSmodule.zeros(shape: { number }): any -- returns nD array
	-- initializes an nD array of zeros of correct shape
	if #shape == 1 then
		local cols = shape[1]
		local tmp = {}
		for i = 1, cols do
			tmp[i] = 0
		end
		return tmp
	else
		-- recursive case
		local tmp = {}
		local shapeTmp = {} -- all except first element of [shape]
		for i = 2, #shape do
			table.insert(shapeTmp, shape[i])
		end

		local outer = shape[1]
		for _ = 1, outer do
			table.insert(tmp, MSmodule.zeros(shapeTmp))
		end
		return tmp
	end
end

function MSmodule.flatToNDIndex(idx: number, shape: { number }): { number }
	-- converts flat index to nD index in an array of shape shape
	local out = {}
	local shapeArr = {}
	for i = 1, #shape do
		local tmp = 1
		for j = i, #shape do
			if j >= #shape then
				tmp = tmp * 1
			else
				tmp = tmp * shape[j + 1]
			end
		end
		shapeArr[i] = tmp
		tmp = 1
	end

	for j, v2 in shapeArr do
		out[j] = math.ceil(idx / v2)
		idx = idx % v2
		if idx == 0 then
			idx = v2
		end
	end
	return out
end

function MSmodule.nDToFlatIndex(idx: { number }, shape: { number }): number
	local flatIdx = 0
	for i, v in idx do
		local accumulator = v - 1
		for j = i + 1, #shape do
			accumulator *= shape[j]
		end
		flatIdx += accumulator
	end
	return flatIdx + 1 -- lua tables start at 1
end

function MSmodule.put(a: any, ind: { number }, v: number, increment: boolean) -- numpy?? who???
	-- accepts ONE index of ONE mine/thing
	for j = 1, (#ind - 1) do
		a = a[ind[j]]
	end
	if increment then
		a[ind[#ind]] += 1
	else
		a[ind[#ind]] = v
	end
end

function MSmodule.TableConcat(t1: { number }, t2: { number }): { number }
	for i = 1, #t2 do
		t1[#t1 + 1] = t2[i]
	end
	return t1
end

function MSmodule.indexOfNearbyTiles(idx: number | { number }, shape: { number }): { { number } }
	-- gets indices of tiles around one mine
	local ndIdx: { number }
	if type(idx) == "number" then
		ndIdx = MSmodule.flatToNDIndex(idx, shape)
	else
		ndIdx = idx
	end
	local dim = ndIdx[1] -- highest dimension
	local transform = { -1, 0, 1 }
	local min, max = 1, shape[1]
	local out = {}
	if #ndIdx == 1 then
		for _, v in transform do
			local tmp = dim + v
			if min <= tmp and tmp <= max then
				table.insert(out, { tmp })
			end
		end
		return out
	else
		local subIdx = {}
		for i, v in ndIdx do
			if i ~= 1 then
				table.insert(subIdx, v)
			end
		end

		local subShape = {}
		for i, v in shape do
			if i ~= 1 then
				table.insert(subShape, v)
			end
		end

		local subDims = MSmodule.indexOfNearbyTiles(subIdx, subShape)

		for _, v in transform do
			local tmp = dim + v
			if min <= tmp and tmp <= max then
				for _, subDim in subDims do
					table.insert(out, MSmodule.TableConcat({ tmp }, subDim))
				end
			end
		end
		return out
	end
end

function MSmodule.toString(arr: { any }, out: any): string
	-- prints a formatted board
	out = out or ""
	if type(arr[1]) == "number" then -- reached a flat array
		out ..= (table.concat(arr, "\t"))
		return out
	else
		for _, v in arr do
			out = out .. ("\n" .. MSmodule.toString(v))
		end
	end
	return out
end

function MSmodule.new(shape: { number }, mines: number): { number }
	local size = 1
	for _, v in shape do
		size *= v
	end
	local mineVal = -(3 ^ #shape) -- mines can get incremented as well, so we set them to -(highest_possible_tile + 1) so they stay negative
	local board = MSmodule.zeros({ size })
	local mineIndices = MSmodule.placeMines(board, mines, mineVal)
	local nDMineIndices: { { number } } = {} -- for getting nearby tiles
	-- we convert flat indices to nD indices to find the indices of nearby tiles more easily
	-- then convert back
	for _, idx in mineIndices do
		table.insert(nDMineIndices, MSmodule.flatToNDIndex(idx, shape))
	end
	local aroundMines = {}
	for _, idx in nDMineIndices do
		for _, nearby in MSmodule.indexOfNearbyTiles(idx, shape) do
			table.insert(aroundMines, MSmodule.nDToFlatIndex(nearby, shape))
		end
	end
	for _, idx in aroundMines do
		board[idx] += 1
	end

	return board
end

return MSmodule
