local rows = {}

local color = require "color"

rows.Player1 = "X"
rows.Player2 = "O"

rows.Rows = 6
rows.Collumns = 7

rows.Player1Color = "red"
rows.Player2Color = "blue"

rows.WinAttribute = "underline"
rows.Turn = "Player1"

function rows:Initialize()
	self.Board = {}
	for i = 1, self.Collumns do 
		self.Board[i] = {}
	end
end

function rows:ChangeTurn()
	if rows.Turn == "Player1" then 
		rows.Turn = "Player2"
	else
		rows.Turn = "Player1"
	end 
end

function rows:Place(player, collumn)
	local Symbol = self[player]
	local h = self:getHeight(collumn)
	if h == self.Rows+1 then 
		-- NOPE
	else 
		self.Board[collumn][h] = Symbol
		self:checkForWin(collumn,h)
		self:PrintBoardState()
		self:ChangeTurn()
	end
end

function rows:GetState(x,y)
	return self.Board[x][y]
end

function rows:PrintBoardState()
	local delim = " " 
	color.save()
	color("%{blackbg}")
	for x=1,self.Collumns do 
		color("%{white}|"..delim..delim)
		for y=self.Rows,1,-1 do 
			local posx = self:GetState(x,y)
			if posx == self.Player1 then 
				color("%{"..self.Player1Color.."}".. posx..delim)
			elseif posx == self.Player2 then 
				color("%{"..self.Player2Color.."}"..posx..delim)
			else 
				io.write(string.rep(" ", self.Player1:len()) .. delim)
			end
		end 
		color(delim.."%{white}|")
		io.write("\n")
	end
	color.restore()
end

function rows:getHeight(collumn) -- returns row height (-1 is last posx)
	for y=1,self.Rows do 
		if not self:GetState(collumn,y) then 
			return y 
		end 
	end  
	return self.Rows
end

function rows:checkForWin(x,y)
	-- HORIZONTAL

	-- VERTICAL

	-- SIDEWAYS


end

function rows:GetAvailableMoves() -- returns a table; values are available moves; yay
	local out = {}
	for x=1,self.Collumns do 
		if self:getHeight(x) ~= self.Rows+1 then -- is full !?
			table.insert(out, x)
		end
	end
	return out
end

function rows:Turn(player, move_collumn)

end

function rows.new()
	return setmetatable({}, {__index=rows})
end

return rows