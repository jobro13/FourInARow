local rows = {}

local color = require "color"

rows.Player1 = "X"
rows.Player2 = "O"

rows.Rows = 6
rows.Collumns = 7

rows.Player1Color = "red"
rows.Player2Color = "yellow"

rows.WinAttribute = "underline"
rows.Turn = "Player1"

-- z0mg hax
rows.Animate = true 
rows.AnimateSleep = 0.1

function rows:Initialize()
	self.Board = {}
	for i = 1, self.Collumns do 
		self.Board[i] = {}
	end
	print(self.Board)
end

function rows:ChangeTurn()
	if rows.Turn == "Player1" then 
		rows.Turn = "Player2"
	else
		rows.Turn = "Player1"
	end 
end

function rows:Place(collumn)
	local Symbol = self[self.Turn]
	local h = self:getHeight(collumn)
	if h == self.Rows+1 then 
		-- NOPE
	else 
		if not self.Animate then 
			self.Board[tonumber(collumn)][tonumber(h)] = Symbol
		else
			local MoveTo = h
			local Start = self.Rows 
			local last_y
			for loop = Start, MoveTo,-1 do 
				self.Board[tonumber(collumn)][tonumber(loop)] = Symbol
				if last_y then 
					self.Board[tonumber(collumn)][tonumber(last_y)] = nil 
				end
				last_y = loop
				self:PrintBoardState()
				os.execute("sleep "..self.AnimateSleep)
			end 
		end 

		self:checkForWin(collumn,h)
		self:ChangeTurn()
	end
end

function rows:GetState(x,y)
	return self.Board[tonumber(x)][tonumber(y)]
end

function rows:PrintBoardState()
	local delim = " " 
	os.execute("tput clear")
	color("%{blackbg}")
	color("%{white}|"..delim..delim)
	for x = 1, self.Collumns do 
		io.write((x)..delim)
	end 
	color(delim.."%{white}|\n")
	for y=self.Rows,1,-1 do 
		color("%{white}|"..delim..delim)
		for x=1,self.Collumns do 
			--print(x.." "..y.." : ".. (self:GetState(x,y) or ""))

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
	local lr = 5 + (self.Collumns * (1 + self.Player1:len()))
	for i = 1, lr do io.write("-") end 
	io.write("\n")
	os.execute("tput rc")
end

function rows:getHeight(collumn) -- returns row height (-1 is posy)
	for y=1,self.Rows do 
		print("check", collumn, y, self:GetState(collumn,y))
		if not self:GetState(collumn,y) then 
			print(y)
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


function rows.new()
	return setmetatable({}, {__index=rows})
end

return rows