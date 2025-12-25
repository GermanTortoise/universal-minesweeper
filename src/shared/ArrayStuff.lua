local ArrayStuff = {}

function ArrayStuff.DictLen(d: { [any]: any }): number
	local count = 0
	for _, _ in d do
		count += 1
	end
	return count
end

return ArrayStuff
