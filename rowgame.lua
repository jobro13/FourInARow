local rows = require "rows"


while true do 
game = rows.new()

game.Animate = false 
game.Minimal = true

game:Initialize()

game:PlayNetGame()
end