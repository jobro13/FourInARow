local rows = {}

local color = require "color"
local gameserver = require "telnet_server"

rows.Player1 = "X"
rows.Player2 = "O"

rows.Rows = 6
rows.Collumns = 7

rows.Player1Color = "red"
rows.Player2Color = "yellow"

rows.WinAttribute = "underline"
rows.Turn = "Player1"
rows.NetGame = false 

rows.Player1Write = io.write 
rows.Player2Write = io.write 

rows.Won = false
rows.PlayerWon = nil

-- z0mg hax
rows.Animate = true 
rows.AnimateSleep = 0.1
rows.SubWinners = true 

rows.Print = true

rows.TurnsTaken = 0 

function rows:Undo() -- undo last move 
	local LastMove = self.Moves[#self.Moves]
	if LastMove then 
		local t= self.Board[LastMove]
		self.Board[LastMove][#t] = nil
		self.Moves[#self.Moves] = nil
		self.TurnsTaken = self.TurnsTaken - 1
		self:ChangeTurn()
	end 
end 

function rows:Initialize()

	self.Board = {}
	self.Moves = {}
	for i = 1, self.Collumns do 
		self.Board[i] = {}
	end
	--print(self.Board)
end

function rows:ChangeTurn()
	if rows.Turn == "Player1" then 
		rows.Turn = "Player2"
	else
		rows.Turn = "Player1"
	end 
end

function rows:Write(str, player, both)
	local game_server = self.GameServer
	if both and self.NetGame then 
		local conn1, conn2 = game_server:GetClientStream("Player1"), game_server:GetClientStream("Player2")
		conn1(str)
		conn2(str)
	elseif self.NetGame then 
		if player == "Other" then 
			local o = "Player1"
			if self.Turn == "Player1" then o = "Player2" end 
			game_server:GetClientStream(o)(str)
		else 
			local conn = game_server:GetClientStream(player)
			conn(str)
		end
	elseif player ~= "Other" then 
		io.write(str)
	end
end 

function rows:Read(player)
	if self.NetGame then 
		return self.GameServer:ReadConnection(player)
	else
		return io.read()
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
			self:PrintBoardState()
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

		table.insert(self.Moves, collumn)
		self.TurnsTaken = self.TurnsTaken + 1

		local won = self:checkForWin(collumn,h)

		if won then 
			self.Won = true 
			self.PlayerWon = self.PlayerWon or self.Turn

			return true, self.PlayerWon 
		end
		self:ChangeTurn()
	end 
	return true
end

function rows:GetState(x,y)
	return self.Board[tonumber(x)][tonumber(y)]
end

function rows:PrintBoardState(addstr)
	if not self.Print then 
		return
	end 
	local lines 
	local line = 0
	if addstr then 
		lines = {}
		for match in addstr:gmatch("[^\n]*") do 
			table.insert(lines, match)
		end
	end 

	function rescol()
		color("%{reset}%{white blackbg}")
	end
	local delim = " " 


	self:Write( string.char(27) .. "[2J", nil, true)
	self:Write( string.char(27) .. "[;H", nil, true)
	self:Write(color("%{blackbg}"), nil, true)
	self:Write(color("%{white}|"..delim..delim), nil, true)

	for x = 1, self.Collumns do 
		self:Write((x)..delim, nil, true)
	end 
	self:Write(color(delim.."%{white}|\n"), nil, true)
	for y=self.Rows,1,-1 do 
		self:Write(color("%{white}|"..delim..delim), nil, true)
		for x=1,self.Collumns do 
			--print(x.." "..y.." : ".. (self:GetState(x,y) or ""))
			rescol()
			local posx = self:GetState(x,y)

			local attr = ""
			if posx and posx:match("%%") then 
				attr = "blink"
			end
			local out = ""
			if posx and posx:match("[^%%]*") == self.Player1 then 
				out = color("%{"..self.Player1Color.." "..attr.."}".. self.Player1 ..delim)
			elseif posx and posx:match("[^%%]*") == self.Player2 then 
				out = color("%{"..self.Player2Color.." "..attr.."}"..self.Player2..delim)
			else 
				out = color("%{white}"..string.rep(" ", self.Player1:len()) .. delim)
			end

			self:Write(out, nil, true)

			line = line + 1
			if addstr and lines[line] then 
				self:Write("   ".. lines[line],nil,true)
			end
		end 
		local out = color(delim.."%{white}|")
		self:Write(out.."\n", nil, true)
	end
	color("%{white}")
	local lr = 5 + (self.Collumns * (1 + self.Player1:len()))
	for i = 1, lr do self:Write("-",nil,true) end 
	self:Write("\n", nil, true)
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
	if self.TurnsTaken >= self.Rows * self.Collumns then 
		self.PlayerWon = "Tied"
		self.Won = true 
		return true 
	end 


	local function fbound(sx,sy,dx,dy,rs) -- start x, start y, delta x, delta y (direction move), (reset with)
		if rs and not self.SubWinners then 
			return 
		end
		local symb = self:GetState(sx,sy)
		local bsymb = symb -- backup symb to check
		local tmpx, tmpy = sx,sy
		while symb do 
			tmpx = tmpx + dx 
			tmpy = tmpy + dy 

				if tmpx < 1 or tmpx > self.Collumns then 
					symb=nil  
				elseif tmpy < 1 or tmpy > self.Rows then 
					symb = nil 
				else   
					symb = self:GetState(tmpx, tmpy)
					symb = symb and symb:match("[^%%]*") == bsymb:match("[^%%]*")
					if rs and symb then
						self.Board[tmpx][tmpy] = bsymb.."%"
					end
				end
		end
		if rs then 
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
		self:Write("Your turn! Write a collumn number to place your disk!", self.Turn)
 
		self:Write(self.Turn.." is placing the disk...", "Other")

		local finished = false
		repeat 
			local coll = tonumber(self:Read( self.Turn))
			if not coll or coll < 1 or coll > self.Collumns then 
				self:Write("Invalid input, try again.", self.Turn)
			elseif coll then 
				finished = self:Place(tonumber(coll))
				if not finished then 
					self:Write("Invalid move, try again.", self.Turn)
				end
			end
		until finished
	end
	self:PrintBoardState() -- to blink!!
	self:Write(self.PlayerWon.." has won!", nil, true)
end

function rows:PlayNetGame() 
	self.NetGame = true 
	self.GameServer = gameserver.new()
	print("Enter IP...")
	self.GameServer:Start(io.read())
	self.GameServer.Server:setoption("reuseaddr", true)
	self.GameServer:AcceptConnection("Player1")
	self.GameServer:GetClientStream("Player1")("\nWaiting for Player 2...")
	self.GameServer:AcceptConnection("Player2")
	self:Play()
end 

function rows:TraceGame() 
	local cturn = self.Turn 
	function switch()
		if cturn == "Player1" then 
			cturn = "Player2"
		else 
			cturn = "Player1"
		end 
	end 
	local out = {}

	for i = #self.Moves,1, -1 do 
		switch()
		out[i] = cturn.." placed his disk in collumn number "..self.Moves[i]
	end 
	for i,v in pairs(out) do 
		print(v)
	end
--	io.read()
end 


function rows.new()
	return setmetatable({}, {__index=rows})
end

return rows