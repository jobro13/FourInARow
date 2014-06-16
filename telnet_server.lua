local tserver = {}

local socket = require "socket"

tserver.MaxClients = 2

-- ET WANTS TO PHONE HOME!

tserver.Port = 0
tserver.BindAdress = "127.0.0.1" 
tserver.Server = nil

function tserver:Start(server,port)
	self.Connections = {}
	self.Server = socket.tcp()
	print(self.Server:bind(server or self.BindAdress, port or self.Port))
	self.Server:listen()
	print(self.Server:getsockname())
end 

function tserver:GetClientStream(client_name)
	if self.Connections[client_name] then 
		return function(str)
			self.Connections[client_name]:send(str)
		end 
	end 
end

function tserver:AcceptConnection(client_name)
	print(self.Server)
	local conn = self.Server:accept()
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