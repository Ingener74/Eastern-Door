local socket = require("socket")

local NetController = class("NetController")

function NetController:ctor(host, port)
	self.sock = assert(socket.connect(host, port))
	-- self.sock:send("{\"method\": \"terminal.get_main_settings\"}\n")
	self.sock:settimeout(0)

    self.schedulerEntry = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function()
		repeat
			local chunk, status, partial = self.sock:receive(1024)
			-- dump(chunk)
			-- dump(status)
			-- dump(partial)

			if partial ~= "" then
				printInfo("Socket receive: " .. partial)
				local data = json.decode(partial)
				dump(data, "json data", 10)
				
				self.sock:close()
				printInfo("Socket closed")						
				cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerEntry)
			end

		until status ~= "closed"
    end, 0, false)
	
end

function NetController.text(str)
	return str
end

function NetController.json(str)
	return json.decode(str)
end

function NetController:request(request, method)
	return Promise.new(function(resolve, reject)
		local method_ = method or NetController.json
	    self.schedulerEntry = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function()
			repeat
				local chunk, status, partial = self.sock:receive(1024)
				if partial ~= "" then

					local data = json.decode(partial)
					dump(data, "json data", 10)
					
					self.sock:close()
					printInfo("Socket closed")						
					cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerEntry)
				end

			until status ~= "closed"
	    end, 0, false)
	end)
end

return NetController