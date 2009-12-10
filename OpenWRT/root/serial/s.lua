function string:split(sSeparator, nMax, bRegexp)
	assert(sSeparator ~= '')
	assert(nMax == nil or nMax >= 1)

	local aRecord = {}

	if self:len() > 0 then
		local bPlain = not bRegexp
		nMax = nMax or -1

		local nField=1 nStart=1
		local nFirst,nLast = self:find(sSeparator, nStart, bPlain)
		while nFirst and nMax ~= 0 do
			aRecord[nField] = self:sub(nStart, nFirst-1)
			nField = nField+1
			nStart = nLast+1
			nFirst,nLast = self:find(sSeparator, nStart, bPlain)
			nMax = nMax-1
		end
		aRecord[nField] = self:sub(nStart)
	end

	return aRecord
end

function update_tmp(file, value)
	if value ~= nil then
		fname = "/tmp/sensors/"..file
		file = io.open(fname,"w")
		file:write(value)
		file:close()
	end
end

serial=io.open("/dev/ttyS0","r+")
serial:write("Serial Port OK")
-- get current time
time = os.time()

for line in serial:lines() do
	-- wait a second for it to clear the read buffer of /dev/ttyS0
	if os.time() - time > 1 then
		splits = string.split(line,"|")
		update_tmp("light",splits[1])
		update_tmp("0",splits[1])
		update_tmp("1",splits[2])
		update_tmp("2",splits[3])
		update_tmp("3",splits[4])
		update_tmp("4",splits[5])
		update_tmp("5",splits[6])
		update_tmp("analogs",line)
		print("c: " .. line)
	end
end

serial:close()
