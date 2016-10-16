local socket = require("socket")

local Net = class("Net")

function Net:ctor(host, port)
	self.sock = assert(socket.connect(host, port))
end

function Net:stop()
	self.sock:close()
end

function Net.text(str)
	return str
end

function Net.json(str)
	return json.decode(str)
end

function Net:request(request, method)
	return Promise.new(function(resolve, reject)
		local method_ = method or Net.json
		self.sock:send(request)
		self.sock:settimeout(0)
	    self.schedulerEntry = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function()
			local status, msg = xpcall(function()
				local chunk, status, partial = self.sock:receive(1024)
				if partial ~= "" then
					cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerEntry)
					resolve(method_(partial))
				end
			end, __G__TRACKBACK__)
			if not status then
			    print(msg)
			    reject(msg)
			end

	    end, 0, false)
	end)
end

function Net:requestJson(req_table, method)
	return self:request(json.encode(req_table), method)
end

return Net