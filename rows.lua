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

rows.Won = false
rows.PlayerWon = nil

-- z0mg hax
rows.Animate = true 
rows.AnimateSleep = 0.1

function rows:Initialize()
	os.execute('tput clear')
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
		return false 
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

		local won = self:checkForWin(collumn,h)
		if won then 
			self.Won = true 
			self.PlayerWon = self.Turn
		end
		self:ChangeTurn()
	end 
	return true
end

function rows:GetState(x,y)
	return self.Board[tonumber(x)][tonumber(y)]
end

function rows:PrintBoardState()
	function rescol()
		color("%{reset}%{white blackbg}")
	end
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
			rescol()
			local posx = self:GetState(x,y)

			local attr = ""
			if posx and posx:match("%%") then 
				attr = "blink"
			end

			if posx and posx:match("[^%%]*") == self.Player1 then 
				color("%{"..self.Player1Color.." "..attr.."}".. self.Player1 ..delim)
			elseif posx and posx:match("[^%%]*") == self.Player2 then 
				color("%{"..self.Player2Color.." "..attr.."}"..self.Player2..delim)
			else 
				color("%{white}"..string.rep(" ", self.Player1:len()) .. delim)
			end
		end 
		color(delim.."%{white}|")
		io.write("\n")
	end
	local lr = 5 + (self.Collumns * (1 + self.Player1:len()))
	for i = 1, lr do io.write("-") end 
	io.write("\n")
	--os.execute("tput home")
end

function rows:getHeight(collumn) -- returns row height (-1 is posy)
	for y=1,self.Rows do 

		if not self:GetState(collumn,y) then 

			return y 
		end 
	end  

	return self.Rows+1
end

function rows:checkForWin(x,y)
	local function fbound(sx,sy,dx,dy,rs) -- start x, start y, delta x, delta y (direction move), (reset with)
		local symb = self:GetState(sx,sy)
		local bsymb = symb -- backup symb to check
		local tmpx, tmpy = sx,sy
		if rs then 
			print("CALL args: ", sx, sy, dx, dy)
		end
		while symb do 
			if rs then print("LOOOP") end 
			tmpx = tmpx + dx 
			tmpy = tmpy + dy 

				if tmpx < 1 or tmpx > self.Collumns then 
					symb=nil 
					if rs then print(tmpx, 'n') end 
				elseif tmpy < 1 or tmpy > self.Rows then 
					symb = nil 
					if rs then print(tmpx, 'o') end 
				else   
					symb = self:GetState(tmpx, tmpy)
					if rs then print(symb, 'symbchk') end 
					symb = symb and symb:match("[^%%]*") == bsymb:match("[^%%]*")
					if rs then print('chk', symb, bsymb) end 
					if rs and symb then
						print("SUB",tmpx,tmpy) 
						self.Board[tmpx][tmpy] = bsymb.."%"
					end
				end
				if rs then 
					print('endloop;', symb, 'h')
				end
		end
		if rs then 
			print("SUB",sx,sy)
			self.Board[sx][sy] = bsymb.."%"
		end
		return tmpx - dx, tmpy - dy -- to fix the bound 
	end



	-- HORIZONTAL
	-- FIND LEFT BOUND:
	local lx = fbound(x,y,-1,0)
	-- FIND RIGHT BOUND
	local rx = fbound(x,y,1,0)
	if rx - lx >= 3 then 
		fbound(x,y,-1,0,true)
		fbound(x,y,1,0,true)
		return true 
	end

	-- VERTICAL

	local _,uy = fbound(x,y,0,1)
	-- FIND RIGHT BOUND
	local _,dy = fbound(x,y,0,-1)
	if math.abs(uy-dy) >= 3 then 
		fbound(x,y,0,1,true)
		fbound(x,y,0,-1,true)
		return true 
	end

	-- SIDEWAYS

	-- down;

	local lx = fbound(x,y,-1,-1)

	local rx = fbound(x,y,1,1)
	if rx - lx >= 3 then 
		fbound(x,y,-1,-1,true) -- replace
		fbound(x,y,1,1,true)
		return true 
	end

	-- up 

	local lx = fbound(x,y,-1,1)
	-- FIND RIGHT BOUND
	local rx = fbound(x,y,1,-1)
	if rx - lx >= 3 then 
		fbound(x,y,-1,1,true)
		fbound(x,y,1,-1,true)
		return true 
	end

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

function rows:Play() -- YEAH :D
	self:PrintBoardState() -- visuals yay
	while not self.Won do 
		print(self.Turn.."'s turn... (type a collumn number to place!)")
		local finished = false
		repeat 
			local coll = tonumber(io.read())
			if not coll or coll < 1 or coll > self.Collumns then 
				print("Invalid input, try again.")
			elseif coll then 
				finished = self:Place(tonumber(coll))
				if not finished then 
					print("Invalid move, try again.")
				end
			end
		until finished
	end
	self:PrintBoardState() -- to blink!!
	print(self.PlayerWon.." has won!")
end


function rows.new()
	return setmetatable({}, {__index=rows})
end

return rows