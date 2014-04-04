--[=[
	'sudoku-solver.lua' - Lua script for use with Rainmeter skins by FlyingHyrax
	Solves valid Sudoku puzzles using constraint propogation and search
	Algorithm courtesy of Peter Norvig, 'Solving Every Sudoku Puzzle'
	< http://norvig.com/sudoku.html >
	
	Author: Flying Hyrax | flyinghyrax.deviantart.com
	Version: 10-12-2013
	CC BY-NC-SA 4.0 < http://creativecommons.org/licenses/by-nc-sa/4.0/ >
]=]

-- definitions for generating cell labels/keys
rows = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'}
cols = {'1', '2', '3', '4', '5', '6', '7', '8', '9'}
rowsqr = {
	{'A', 'B', 'C'},
	{'D', 'E', 'F'},
	{'G', 'H', 'I'}
}
colsqr = {
	{'1', '2', '3'},
	{'4', '5', '6'},
	{'7', '8', '9'}
}
cells = {}		-- a list of all 81 cell labels
unitlist = {}	-- a list of lists, where each is a unit of labels
units = {}		-- a list with each cell mapped to its lists of units
peers = {}		-- a list with each cell mapped to a list of peers

measures = {}	-- list for the measures that hold cell values in the skin

status = nil
BulletTime = false	-- controls whether or not the skin Updates every time a value is placed

function Update()
	return status
end

-- Given a string or number, sets the text of the 'statusMessage' meter to
-- that value and updates the skin
function SetStatus(text)
	status = text
	SKIN:Bang('!SetOption', 'statusMessage', 'Text', text)
	SKIN:Bang('!Update')
end

-- script setup; runs on skin load and refresh
-- generates the lists of keys, units, peers, and measure objects
function Initialize()
	SetStatus('initializing...')
	-- Generate list of all grid cells:
	cells = Cross(rows, cols)
	-- Generate list of unit lists:
	for _, c in pairs(cols) do	-- column units
		table.insert(unitlist, Cross(rows, c))
	end
	for _, r in pairs(rows) do	-- row units
		table.insert(unitlist, Cross(r, cols))
	end
	for _, rs in pairs(rowsqr) do -- box units
		for _, cs in pairs(colsqr) do
			table.insert(unitlist, Cross(rs, cs))
		end
	end
	
	-- now that we have our list of cells and list of units, for each cell:
	for cell, _ in pairs(cells) do
		
		-- generate a hashtable mapping of keys to unit lists
		units[cell] = {}	-- init
		-- for each unit list
		for _, unit in pairs(unitlist) do
			-- test if this cell is in this unit
			if unit[cell] then
				-- if yes, add that unit list to the units collection for this cell
				table.insert(units[cell], unit)
			end
		end
		
		-- generate a hashtable mapping of keys to peers:
		peers[cell] = {}	-- init
		-- for each unit list for this cell
		for _, unit in pairs(units[cell]) do
			-- for every cell in this unit list
			for peer, _ in pairs(unit) do
				-- excluding the cell itself
				if peer ~= cell then
					-- add the member of the unit list to a list of peers for this cell
					peers[cell][peer] = true
				end
			end
		end
		
		-- populate the measures table w/ references to skin measures:
		measures[cell] = SKIN:GetMeasure('m' .. cell)
	end
	
	BulletTime = SELF:GetOption('SlowMotion', '0') == '1' and true or false
	SetStatus('ready')
end

-- called from skin: gets clue cells from skin, validates the puzzle,
-- and solves the puzzle if it is valid
function Solve()
	SetStatus('solving...')
	
	local puzzle = InitPuzzle()
	local clues = GetSkinClues()
	local valid = true
	for cell, value in pairs(clues) do
		if not Place(puzzle, cell, value) then
			valid = false
			break
		end
	end
	
	if valid then
		local result = Search(puzzle)
		if result then
			SetStatus('solved')
			PopulateSkin(result)
		else
			SetStatus('unsolved')
			PopulateSkin(puzzle)
		end
	else
		SetStatus('invalid puzzle')
		PopulateSkin(puzzle)
	end
end

-- Returns a table mapping every cell to a set of digits 1..9
function InitPuzzle()
	local values = {}
	for cell, _ in pairs(cells) do
		values[cell] = {[1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true, [9]=true}
	end
	return values
end

-- Returns a table mapping clue cells in the skin with their values
-- by checking cell measures which have a value other than 0
function GetSkinClues()
	local values = {}
	for cell, msr in pairs(measures) do
		local val = msr:GetValue()
		-- if the retrieved value is in our list of digits 1..9
		if cols[val] then
			values[cell] = val
		end
	end
	return values
end

-- assigns value 'v' to cell 'c' in puzzle table 'values'
function Place(values, c, v)
	for otherv, _ in pairs(values[c]) do
		if otherv == v then
			values[c][otherv] = true
		else 
			if not RemoveVal(values, c, otherv) then
				return false
			end
		end
	end
	if BulletTime then
		PutSkinVal(c, v)
	end
	return values
end

-- removes value 'v' from set of possibilities for cell 'c' in the puzzle table 'values'
function RemoveVal(values, c, v)
	
	if not values[c][v] then
		return true	-- v is not in list for c - already removed
	else
		values[c][v] = nil	-- remove v from c's list of possible values
	end
	
	local len = Count(values[c])
	if len == 0 then
		-- if the cell has 0 options left, there is a contradiction
		return false
	elseif len == 1 then
		-- if the cell has 1 option left, trigger first rule
		if not EliminateFromPeers(values, c, First(values[c])) then
			return false	-- contradiction further up the call stack
		end
		if BulletTime then
			PutSkinVal(c, First(values[c]))
		end
	else
		-- if the cell has >1 options left, tirgger second rule
		if not UnitCheck(values, c, v) then
			return false
		end
	end
	
	return true -- removal and any subsequent propagation was successful
end

-- FIRST RULE: 
-- if a cell has only one possible value, eliminate that value from the cell's peers
function EliminateFromPeers(values, c, v)
	-- print('eliminating ' .. v .. ' from peers of ' .. c)
	for peer, _ in pairs(peers[c]) do
		if not RemoveVal(values, peer, v) then
			return false
		end
	end
	return true
end

-- SECOND RULE: 
-- if a unit has only one place for a value, put that value in that place
function UnitCheck(values, c, v)
	-- for each unit that contains cell c:
	for _, unit in pairs(units[c]) do
		local places = {}
		-- for each cell in this unit:
		for unitc, _ in pairs(unit) do
			-- track the cells that have v as a possible value:
			if values[unitc][v] then
				places[unitc] = true
			end
		end
		-- if there is only one cell with v as an option in this unit:
		if Count(places) == 1 then
			-- put v in that cell
			if not Place(values, First(places), v) then
				return false
			end
		end
	end
	return true	-- any placement was successful
end

-- recursive search/guessing function to go where pure deduction cannot
function Search(values)
	-- check if we broke earlier
	if not values then 
		return false 
	end
	-- check if 'solved'
	local solved = true
	for c, vals in pairs(values) do
		if Count(vals) ~= 1 then
			solved = false
			break
		end
	end
	if solved then
		return values
	end
	-- if not solved, find cell w/ fewest values
	local minc = nil
	for c, vals in pairs(values) do
		local lenvals = Count(vals)
		if lenvals > 1 then
			if not minc or lenvals < Count(values[minc]) then
				minc = c
			end
		end
	end
	-- for every possible value of minc, assign that value to a new copy
	-- of the values table and see if it works
	for kv, _ in pairs(values[minc]) do
		local valuesCopy = CopyVals(values)
		local retval = Search(Place(valuesCopy, minc, kv))
		if retval then 
			return retval
		end
	end
	-- if we reach here, then no recurrence from above solved the puzzle
	return false
end

-- returns a copy of a puzzle/values table
function CopyVals(values)
	local copy = {}
	for cell, vals in pairs(values) do
		copy[cell] = {}
		for kv, b in pairs(vals) do
			copy[cell][kv] = b
		end
	end
	return copy
end

-- count items in a set (table of key=true pairs)
function Count(set)
	local n = 0
	for kv, b in pairs(set) do
		if b then
			n = n + 1
		end
	end
	return n
end

-- returns the first key in a set (table of key=true pairs)
-- or nil if empty (or some other error)
function First(set)
	local f = nil
	for k, b in pairs(set) do
		f = k
		break
	end
	return f
end

-- given a cell and a value, sets the 'Formula=<value>' in the measure m<cell>;
-- used to populate the skin with results during/after solving the puzzle
-- Putting an '!Update' bang causes the cool cell population effect,
-- though it takes time: we could update ONCE in PopulateSkin()
function PutSkinVal(cell, value)
	local msr = measures[cell]:GetName()
	SKIN:Bang('!SetOption', msr, 'Formula', value)
	SKIN:Bang('!UpdateMeasure', msr)
	if BulletTime then
		SKIN:Bang('!Update')
	end
end

-- Uses putSkinVal to set every cell in the skin using the 'values' table 
-- (which represents the puzzle).  Any cell with more than one possible value 
-- is set to 0 (blank).
function PopulateSkin(values)
	for cell, vals in pairs(values) do
		if Count(vals) == 1 then
			PutSkinVal(cell, First(vals))
		else
			PutSkinVal(cell, 0)
		end
	end
	if not BulletTime then
		SKIN:Bang('!Update')
	end
end

-- Creates a set of string keys: all values for keys in the table are 'true',
-- which makes it trivial to check if a table contains a value.
-- Used to create tables of cells and units
function Cross(t1, t2)
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