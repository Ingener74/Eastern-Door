
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

function MainScene:onCreate()
	local buttons = {}

	table.insert(buttons, self:addButton("Open socket", function()
		printInfo("Open socket")

		local status, msg = xpcall(function()
			local socket = require("socket")
			local host = "127.0.0.1"
			self.sock = assert(socket.connect(host, 9999))
			self.sock:send("{\"method\": \"terminal.get_main_settings\"}\n")
		end, __G__TRACKBACK__)
		if not status then
		    print(msg)
		end
	end))
	table.insert(buttons, self:addButton("Open socket", function()
		local status, msg = xpcall(function()
			self.sock:settimeout(0)
			repeat
				local chunk, status, partial = self.sock:receive(1024)
				printInfo("received")
				dump(chunk)
				dump(status)
				dump(partial)
			until status ~= "closed"
		end, __G__TRACKBACK__)

		if not status then
		    print(msg)
		end

	end))
	table.insert(buttons, self:addButton("Close socket", function()
		local status, msg = xpcall(function()
			self.sock:close()
			printInfo("Socket closed")
		end, __G__TRACKBACK__)
		if not status then
		    print(msg)
		end
	end))

	table.insert(buttons, self:addButton("Read settings", function()
		local status, msg = xpcall(function()
			local socket = require("socket")
			local host = "127.0.0.1"
			self.sock = assert(socket.connect(host, 9999))
			self.sock:send("{\"method\": \"terminal.get_main_settings\"}\n")
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

		end, __G__TRACKBACK__)
		if not status then
		    print(msg)
		end
	end))

	local x = 8
	local y = display.height - 8

	for i,button in ipairs(buttons) do
		button:setPosition(x, y)

		x = x + button:getContentSize().width + 8
	end
end

function MainScene:addButton(title, handler)
	local button = ccui.Button:create("button.png", "buttonHighlighted.png", "buttonHighlighted.png")
	button:setAnchorPoint(0, 1)
	button:setScale9Enabled(true)
	button:setContentSize(120, 40)
	button:setTitleText(title)
	button:addClickEventListener(handler)
	self:addChild(button)
	return button
end

return MainScene
