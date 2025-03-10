local MSmodule = {}

function MSmodule.rSample(n: number, max: number): { number }?
	-- n unique random ints from 1 to range
	if n > max then -- check for bad input
		error(string.format("%d random ints out of bounds for range %d", n, max))
		return nil
	end

	math.randomseed(os.time())
	local out = {}
	for _ = 1, n do
		local try = math.random(1, max)
		while out[try] do
			try = math.random(1, max)
		end
		out[try] = try
	end
	return out
end

function MSmodule.zeros(shape)
	-- gave up on strict type checking here
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

function MSmodule.empty(shape)
	-- gave up on strict type checking here
	-- initializes an nD array of zeros of correct shape
	if #shape == 1 then
		return {}
	else
		-- recursive case
		local tmp = {}
		local shapeTmp = {} -- all except first element of [shape]
		for i = 2, #shape do
			table.insert(shapeTmp, shape[i])
		end

		local outer = shape[1]
		for _ = 1, outer do
			table.insert(tmp, MSmodule.empty(shapeTmp))
		end
		return tmp
	end
end

function MSmodule.flatToShapedIndices(idx, shape)
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

	for j, v2 in pairs(shapeArr) do
		out[j] = math.ceil(idx / v2)
		idx = idx % v2
		if idx == 0 then
			idx = v2
		end
	end
	return out
end

function MSmodule.get(arr, idx: { number })
	-- print(arr)
	-- print(idx)
	for _, v in ipairs(idx) do
		arr = arr[v]
	end
	return arr
end

function MSmodule.put(arr, idx: { number }, v, increment: boolean) -- numpy?? who???
	-- accepts ONE index of ONE mine/thing
	for j = 1, (#idx - 1) do
		arr = arr[idx[j]]
	end
	if increment then
		arr[idx[#idx]] += 1
	else
		-- print(arr)
		-- print(idx)
		arr[idx[#idx]] = v
	end
	return arr
end

function MSmodule.TableConcat(t1, t2)
	for i = 1, #t2 do
		t1[#t1 + 1] = t2[i]
	end
	return t1
end

function MSmodule.indexNearbyTiles(idx, shape)
	-- gets indices of tiles around one mine
	local dim = idx[1]
	local transform = { -1, 0, 1 }
	local min, max = 1, shape[1]
	local out = {}
	if #idx == 1 then
		for _, v in transform do
			local tmp = dim + v
			if min <= tmp and tmp <= max then
				table.insert(out, { tmp })
			end
		end
		return out
	else
		local subIdx = {}
		for i, v in ipairs(idx) do
			if i ~= 1 then
				table.insert(subIdx, v)
			end
		end

		local subShape = {}
		for i, v in ipairs(shape) do
			if i ~= 1 then
				table.insert(subShape, v)
			end
		end

		local subDims = MSmodule.indexNearbyTiles(subIdx, subShape)

		for _, v in transform do
			local tmp = dim + v
			if min <= tmp and tmp <= max then
				for _, subDim in pairs(subDims) do
					table.insert(out, MSmodule.TableConcat({ tmp }, subDim))
				end
			end
		end
		return out
	end
end

function MSmodule.toString(arr, out)
	-- prints a formatted board
	local out = out or ""
	if type(arr[1]) == "number" then -- reached a flat array
		out = out .. (table.concat(arr, "\t"))
		return out
	else
		for _, v in ipairs(arr) do
			out = out .. ("\n" .. MSmodule.toString(v))
		end
	end
	return out
end

function MSmodule.new(shape: { number }, mines: number)
	local size = 1
	for _, v in ipairs(shape) do
		size *= v
	end
	local board = MSmodule.zeros(shape)
	local mineIndices = MSmodule.rSample(mines, size) -- 1D list of indices
	local mineMin = -(3 ^ #shape)
	local shapedMineIndices = {}

	for _, idx in pairs(mineIndices) do
		table.insert(shapedMineIndices, MSmodule.flatToShapedIndices(idx, shape))
	end

	local aroundMines = {}
	for _, idx in pairs(shapedMineIndices) do
		table.insert(aroundMines, MSmodule.indexNearbyTiles(idx, shape))
	end

	for _, v in ipairs(shapedMineIndices) do
		MSmodule.put(board, v, mineMin, false)
	end

	for _, eachMine in ipairs(aroundMines) do
		for _, tile in ipairs(eachMine) do
			MSmodule.put(board, tile, 0, true)
		end
	end
	return board
end

return MSmodule
