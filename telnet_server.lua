local tserver = {}

local socket = require "socket"

tserver.MaxClients = 2

-- ET WANTS TO PHONE HOME!

tserver.Port = 60302
tserver.BindAdress = "192.168.1.21" 
tserver.Server = nil

GLOBAL = nil

function tserver:Start(server,port)
	self.Connections = {}
	self.Server = GLOBAL or  socket.tcp()
	if not GLOBAL then 
	print(self.Server:bind(server or self.BindAdress, port or self.Port))
	self.Server:listen()
	print(self.Server:getsockname())
	GLOBAL = self.Server
	end
end 

function tserver:Close()
	for i,v in pairs(self.Connections) do 
		v:close()
	end 
	--self.Server:close()
end 

function tserver:GetClientStream(client_name)
	--print(client_name)
	if self.Connections[client_name] then 
		--print(self.Connections[client_name])

		return function(str)
			self.Connections[client_name]:send(str)
		end 
	end 
end

function tserver:AcceptConnection(client_name)
	print(self.Server)
	local conn = self.Server:accept()
	print(conn:getpeername())
	conn:send("Hello, you are: "..client_name)
	self.Connections[client_name] = conn
end 

function tserver:ReadConnection(client_name)
	if self.Connections[client_name] then 
		return self.Connections[client_name]:receive()
	end
end

function tserver.new()
	return setmetatable({} , {__index = tserver})
end 

return tserver