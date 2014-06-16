local rows = require "rows"

game = rows.new()
game:Initialize()

for i = 1, 7 do game:Place(math.random(1,7)) end 