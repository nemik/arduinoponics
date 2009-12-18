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
		--print("wrote "..value.." to "..fname)
	end
end

function update_micro(file, tty)
	if value ~= nil then
		fname = "/tmp/digital/"..file
		f = io.open(fname,"r")
		value = f:read()
		f:close()
		tty:write(value)
		print(value.." written to tty")
		f = io:open(fname,"w")
		f:write("")
		f:close()
	end
end

function toggle_lights(tty)
	lf = io.open("/tmp/sensors/light","r")
	v = lf:read()
	lf:close()
	if(v == '1') then
		tty:write('l')
		f = io.open("/tmp/sensors/light","w+")
		f:close()
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
		update_tmp("analogs",line)
		update_tmp("0",splits[1])
		update_tmp("1",splits[2])
		update_tmp("2",splits[3])
		update_tmp("3",splits[4])
		update_tmp("4",splits[5])
		update_tmp("5",splits[6])
		print("c: " .. line)
		toggle_lights(serial)
	end
end

serial:close()
