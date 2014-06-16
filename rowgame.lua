local rows = require "rows"

game = rows.new()

game.Animate = false 
game.Minimal = true

game:Initialize()

game:PlayNetGame()
