local ArrayStuff = {}

function ArrayStuff.DictLen(d: { [any]: any }): number
	local count = 0
	for _, _ in d do
		count += 1
	end
	return count
end

--[[
Concatenates array-like (no gaps) tables
]]
function ArrayStuff.TableConcat(t1: { any }, t2: { any }): { any }
	for i = 1, #t2 do
		t1[#t1 + 1] = t2[i]
	end
	return t1
end

return ArrayStuff
