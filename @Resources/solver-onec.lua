-- version of the sudoku solver that only implements the first rule, i.e.
-- 'if a cell has only one possible value, then eliminate that value from its peers'
-- no search/guessing function

rows = {"A", "B", "C", "D", "E", "F", "G", "H", "I"}
cols = {"1", "2", "3", "4", "5", "6", "7", "8", "9"}
rowsqr = {
	{"A", "B", "C"},
	{"D", "E", "F"},
	{"G", "H", "I"}
}
colsqr = {
	{"1", "2", "3"},
	{"4", "5", "6"},
	{"7", "8", "9"}
}

cells, unitlist, units, peers, measure = {}, {}, {}, {}, {}
status = nil
BulletTime = false

function Update()
	return status
end

function setStatus(text)
	status = text
	SKIN:Bang('!SetOption', 'statusMessage', 'Text', text)
	SKIN:Bang('!Update')
end

function Initialize()
	setStatus("initializing...")
	
	cells = cross(rows, cols)
	
	for _, c in pairs(cols) do	-- column units
		table.insert(unitlist, cross(rows, c))
	end
	for _, r in pairs(rows) do	-- row units
		table.insert(unitlist, cross(r, cols))
	end
	for _, rs in pairs(rowsqr) do -- box units
		for _, cs in pairs(colsqr) do
			table.insert(unitlist, cross(rs, cs))
		end
	end
	
	for cell, _ in pairs(cells) do
		
		units[cell] = {}	-- init
		for _, unit in pairs(unitlist) do
			if unit[cell] then
				table.insert(units[cell], unit)
			end
		end
		
		peers[cell] = {}	-- init
		for _, unit in pairs(units[cell]) do
			for peer, _ in pairs(unit) do
				if peer ~= cell then
					peers[cell][peer] = true
				end
			end
		end
		
		measures[cell] = SKIN:GetMeasure('m' .. cell)
	end
	
	BulletTime = SELF:GetOption('SlowMotion', '0') == '1' and true or false
	setStatus("ready")
end

function solve()
	setStatus('solving...')
	
	local values = initValues()
	local clues = getSkinClues()
	local isValid = true
	for cell, value in pairs(clues) do
		if not place(values, cell, value) then
			isValid = false
			break
		end
	end
	
	if isValid then
		setStatus('done for now')
		populateSkin(values)
	else
		setStatus('invalid puzzle')
	end
end

function initValues()
	local values = {}
	for cell, _ in pairs(cells) do
		values[cell] = {[1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true, [9]=true}
	end
	return values
end

function getSkinClues()
	local values = {}
	for cell, msr in pairs(measures) do
		local val = msr:GetValue()
		if cols[val] then
			values[cell] = val
		end
	end
	return values
end

function place(values, c, v)
	for otherv, _ in pairs(values[c]) do
		if otherv == v then
			values[c][otherv] = true
		else 
			if not removeVal(values, c, otherv) then
				return false
			end
		end
	end
	if BulletTime then
		putSkinVal(c, v)
	end
	return true
end

function eliminateFromPeers(values, c, v)
	for peer, _ in pairs(peers[c]) do
		if not removeVal(values, peer, v) then
			return false
		end
	end
	return true
end

function removeVal(values, c, v)
	if not values[c][v] then
		return true	-- v is not in list for c - already removed
	else
		values[c][v] = nil	-- remove v from c's list of possible values
	end
	local len = countVals(values[c])
	if len == 0 then
		return false -- houston, we have a contradiction (last possibility removed)
	elseif len == 1 then
		if not eliminateFromPeers(values, c, firstVal(values[c])) then
			return false	-- contradiciton further down the line
		end
		if BulletTime then
			putSkinVal(c, firstVal(values[c]))
		end
	end
	return true -- removal and any subsequent propagation was successful
end

function countVals(cellVals)
	local n = 0
	for val, bool in pairs(cellVals) do
		n = n + 1
	end
	return n
end

function firstVal(cellVals)
	local v = nil
	for val, bool in pairs(cellVals) do
		v = val
		break
	end
	return v
end

function putSkinVal(cell, value)
	local msr = measures[cell]:GetName()
	SKIN:Bang('!SetOption', msr, 'Formula', value)
	SKIN:Bang('!UpdateMeasure', msr)
	if BulletTime then
		SKIN:Bang('!Update')
	end
end

function populateSkin(values)
	for cell, vals in pairs(values) do
		if countVals(vals) == 1 then
			putSkinVal(cell, firstVal(vals))
		else
			putSkinVal(cell, 0)
		end
	end
	if not BulletTime then
		SKIN:Bang('!Update')
	end
end

function cross(t1, t2)
	local result = {}
	if type(t1) ~= 'table' then
		for _, v in pairs(t2) do
			result[t1..v] = true
		end
	elseif type(t2) ~= 'table' then
		for _, v in pairs(t1) do
			result[v..t2] = true
		end
	else
		for _, v1 in pairs(t1) do
			for _, v2 in pairs(t2) do
				result[v1..v2] = true
			end
		end
	end
	return result
end