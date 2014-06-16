print("Trying all possible combinations via a tree-search...")

local rows = require "rows"

local game = rows.new()
game:Initialize()
game.Animate = false 
game.SubWinners = false 
game.Print = false 

game.Rows = 4
game.Collumns = 3

local WINS = {}

local GAME_NO = 0

function recurse()
	local possible = game:GetAvailableMoves()
	for index, collumn in pairs(possible) do 
		GAME_NO = GAME_NO + 1
		local _,won = game:Place(collumn)
		io.write( string.char(27) .. "[;H"..string.char(27).."[8B")
		for i,v in pairs(WINS) do 
			print(i.." : "..v)
		end 
		print(GAME_NO)
		if GAME_NO % 1000 == 1 then 
			game.Print = true
			game:PrintBoardState()
			game.Print = false 
		end 
		--os.execute("sleep 0.0")
		if not won then 
			recurse()
		end
		if won == "Player1" then 
			--game:TraceGame()
			--io.read()
		end 
		game:Undo()

		if won then 
			if not WINS[won] then 
				WINS[won] = 0
			end 
			WINS[won] = WINS[won] + 1
			return
		end
	end 
end 

recurse()

for i,v in pairs(WINS) do 
	print(i,v)
end 