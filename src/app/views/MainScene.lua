
local Net = require("app.controllers.Net")

local MainScene = class("MainScene", cc.load("mvc").ViewBase)

MainScene.BUTTON_WIDTH = 160
MainScene.BUTTON_HEIGHT = 40
MainScene.PADDING = 8
MainScene.BUTTON_FONT_SIZE = 16

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

	self._text = cc.Label:createWithTTF("Text", "fonts/Arial Bold.ttf", 24)
	self._text:setAnchorPoint(0, 1)
	self._text:setPosition(8, display.height - 200)
	self:addChild(self._text)

	table.insert(buttons, self:addButton("Create net", function()
		self._net = Net:create('127.0.0.1', 9999)
	end))

	table.insert(buttons, self:addButton("Net request m1, m2", function()
		self._net:request("{\"method\":\"m1\"}"):andThen(function(result)
			dump(result)
			return self._net:request("{\"method\":\"m2\"}")
		end):andThen(function(result)

			self._text:setString(string.format("m2 = %d", result.result))
			dump(result)

		end):catch(function(err)
			printError(err)
		end)
	end))

	table.insert(buttons, self:addButton("Net request m3, m4", function()
		self._net:requestJson({method = "m3"}):andThen(function(result)
			dump(result)
			return self._net:requestJson({method = "m4"})
		end):andThen(function(result)
			
			self._text:setString(string.format("m4 = %d", result.result.r3))
			dump(result)

		end):catch(function(err)
			printError(err)
		end)
	end))

	table.insert(buttons, self:addButton("Remove net", function()
		self._net:requestJson({method = "quit"})
		self._net:stop()
	end))

	local x = self.PADDING
	local y = display.height - self.PADDING

	for i,button in ipairs(buttons) do
		button:setPosition(x, y)

		x = x + button:getContentSize().width + self.PADDING
		if (x + self.BUTTON_WIDTH + self.PADDING) >= display.width then
			x = self.PADDING
			y = y - self.BUTTON_HEIGHT - self.PADDING
		end
	end
end

function MainScene:addButton(title, handler)
	local button = ccui.Button:create("button.png", "buttonHighlighted.png", "buttonHighlighted.png")
	button:setAnchorPoint(0, 1)
	button:setScale9Enabled(true)
	button:setContentSize(self.BUTTON_WIDTH, self.BUTTON_HEIGHT)
	button:setTitleText(title)
	button:setTitleFontSize(self.BUTTON_FONT_SIZE)
	button:addClickEventListener(handler)
	self:addChild(button)
	return button
end

return MainScene
