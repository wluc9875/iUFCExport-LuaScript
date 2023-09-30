-- Copyright (c) 2021-present Luc WALTERTHUM
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License along
-- with this program; if not, write to the Free Software Foundation, Inc.,
-- 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

--
-- Acknowledgments:
-- jboecker for providing a simple and clear skeleton of a DCS Script to export/import data
-- https://github.com/jboecker/dcs-arduino-example
--



iUFCExport = {}
iUFCExport.HOST = "224.0.0.1" -- local network multicast IP address
--iUFCExport.HOST = "192.168.86.33" -- local network multicast IP address
iUFCExport.OUTBOUND_PORT = 7676 -- change this port if already taken. If you do that, don't forget to adjust the iPad application ports too.
iUFCExport.INBOUND_PORT = iUFCExport.OUTBOUND_PORT + 1

package.path = package.path..";.\\LuaSocket\\?.lua"
package.cpath = package.cpath..";.\\LuaSocket\\?.dll"

socket = require("socket")

local PrevExport = {}
PrevExport.LuaExportStart = LuaExportStart
PrevExport.LuaExportStop = LuaExportStop
PrevExport.LuaExportBeforeNextFrame = LuaExportBeforeNextFrame
PrevExport.LuaExportAfterNextFrame = LuaExportAfterNextFrame

local aircraft = ""

--
-- initialization, called at start of mission
--

LuaExportStart = function()
	iUFCExport.outboundConn = socket.udp()
	iUFCExport.outboundConn:setsockname("*", 0)
	iUFCExport.outboundConn:setoption("broadcast", true)
	iUFCExport.outboundConn:settimeout(0)

	iUFCExport.inboundConn = socket.udp()
	iUFCExport.inboundConn:setsockname("*", iUFCExport.INBOUND_PORT)
	iUFCExport.inboundConn:settimeout(0)
	
	aircraft = LoGetSelfData()["Name"]

	if PrevExport.LuaExportStart then
		PrevExport.LuaExportStart()
	end
end

--
-- cleanup, called at end of mission
--

LuaExportStop = function()
	iUFCExport.inboundConn:close()
	iUFCExport.outboundConn:close()

	if PrevExport.LuaExportStop then
		PrevExport.LuaExportStop()
	end
end

--
-- Interpret the commands sent from the iPad
--

local forcedUpdate = false

local function processCommand(line)
	local deviceIdString, commandIdString, argumentString = line:match("^([^ ]+) ([^ ]+) (.*)")
	local deviceId = tonumber(deviceIdString)
	local commandId = tonumber(commandIdString)
	local argument = tonumber(argumentString)
	
	if deviceId ~= 999 then
		GetDevice(deviceId):performClickableAction(commandId, argument)
	else
		forcedUpdate = true
	end
end

--
-- Check for data coming from the inbound connection
--

local receivedData = ""
LuaExportBeforeNextFrame = function()
	iUFCExport.inboundConn:settimeout(0.001)
	
	local dataChunk = nil
	while true do
		dataChunk = iUFCExport.inboundConn:receive()
		
		if not dataChunk then 
			break
		end
		
		receivedData = receivedData .. dataChunk
	end
	
	-- if there's a complete line, process it as a command

	while true do
		local line, rest = receivedData:match("^([^\n]+)\n(.*)")
		if line then
			receivedData = rest
			processCommand(line)
		else
			break
		end
	end

	if PrevExport.LuaExportBeforeNextFrame then
		PrevExport.LuaExportBeforeNextFrame()
	end
end

--
-- build DCS output line
--

local function buildDCSOutput(customEntries, listEntries)
	local dcsOutput = ""
	local device0 = GetDevice(0)
	if customEntries ~= nil then
		for key, value in pairs(customEntries) do
			dcsOutput = dcsOutput .. "-\n" .. key .. "\n"
			for indKey, indValue in ipairs(value) do
				if indKey > 1 then
					dcsOutput = dcsOutput .. " "
				end
				dcsOutput = dcsOutput .. device0:get_argument_value(indValue)
			end
			dcsOutput = dcsOutput .. "\n"
		end
	end
	if listEntries ~= nil then
		for key, value in ipairs(listEntries) do
			dcsOutput = dcsOutput .. list_indication(value)
		end
	end
	return dcsOutput
end

--
-- Read DCS displays content and instrument data depending on the current plane
--

local function getIndicators()
	local indicators = ""
	local device0 = GetDevice(0)
	if aircraft:find("A%-10C") then
		indicators = buildDCSOutput({caution = {404},
			cmsswitches={360, 361, 362, 363, 358, 364}}, 
			{7}) -- CMSP lines
	elseif aircraft:find("AJS37") then
		indicators = buildDCSOutput({datasel = {200}, -- CK37 data selector
			inut = {201},
			cmsswitches={317, 318, 319, 321, 322, 320}},
			{2}) -- CK37 displayed data
	elseif aircraft:find("F%-16") then
		indicators = buildDCSOutput({flirgain = {189}, driftco = {186},
			cmsswitches={375, 374, 373, 371, 365, 366, 367, 368, 377, 378}}, {16})
	elseif aircraft:find("FA%-18") then 
		indicators = buildDCSOutput({adf={107},
			cmsswitches={517, 248}},
			{6}) -- UFC lines
	elseif aircraft:find("AV8") then 
		indicators = buildDCSOutput(nil, {5, 6}) -- UFC + ODU
	elseif aircraft:find("JF%-17") then 
		indicators = buildDCSOutput({lights={150, 151, 152, 153, 154, 155}}, -- UFCP button lights
			{3, 4, 5, 6}) -- the 4 UFC 
	elseif aircraft:find("M%-2000") then 
		indicators = buildDCSOutput({rotator={574}, -- PCN ROTATOR
			lights={595, 597, 571, 573, 577, 579, 581, 583}, -- PCN lights (TODO not working properly)
			cmsswitches={605, 606, 607, 608, 609, 610}},
			{9, 10}) -- PCN display lines
	elseif aircraft:find("Ka%-50") then 
		indicators = buildDCSOutput({rotator={324}, -- PVI rotator
			fixmethod={325}, -- PVI fix method
			datalink={326}, -- PVI datalink
			lights={315, 151, 316, 520, 317, 521, 318, 313, 314, 522, 319, 320, 321, 322, 323}, -- PVI lights
			cmsswitches={36, 541, 542, 37}}, 
			{5, 7}) -- PVI display lines + UV26 
	elseif aircraft:find("AH%-64D") then
		indicators = buildDCSOutput(nil, {15})
	elseif aircraft:find("F%-15E") then 
		indicators = buildDCSOutput(nil, {9})
	end
	return indicators
end

--
-- Sends instrument data and displays content to the iPad every 0.2 seconds
-- Check current aircraft every 2 seconds, to support multi-player and aircraft change in middle of game
--

local nextUpdate = 0
local nextAircraftCheck = 0
local previousIndicators = ""
LuaExportAfterNextFrame = function()
	local curTime = LoGetModelTime()
	
	if curTime >= nextAircraftCheck then
		nextAircraftCheck = curTime + 2
		aircraft = LoGetSelfData()["Name"]
	end

	if curTime >= nextUpdate then
		nextUpdate = curTime + 0.2
		local indicators = getIndicators()
		if forcedUpdate or indicators ~= previousIndicators then
			socket.try(iUFCExport.outboundConn:sendto(indicators, iUFCExport.HOST, iUFCExport.OUTBOUND_PORT))
			previousIndicators = indicators
			forcedUpdate = false
		end
	end

	if PrevExport.LuaExportAfterNextFrame then
		PrevExport.LuaExportAfterNextFrame()
	end
end 
