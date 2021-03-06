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

local function processCommand(line)
	local deviceIdString, commandIdString, argumentString = line:match("^([^ ]+) ([^ ]+) (.*)")
	local deviceId = tonumber(deviceIdString)
	local commandId = tonumber(commandIdString)
	local argument = tonumber(argumentString)
	
	GetDevice(deviceId):performClickableAction(commandId, argument)
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
-- Read DCS displays content and instrument data depending on the current plane
--

local function getIndicators()
	local indicators = ""
	local device0 = GetDevice(0)
	if aircraft:find("F%-16") then
		indicators = "-\nflirgain\n" .. device0:get_argument_value(189)  .. "\n" .. -- FLIR GAIN switch position
			"-\ndriftco\n" .. device0:get_argument_value(186)  .. "\n" -- DRIFT C/O switch position
	elseif aircraft:find("FA%-18") then 
		indicators = "-\nadf\n" .. device0:get_argument_value(107)  .. "\n" .. -- ADF switch position
			list_indication(6) -- UFC
	elseif aircraft:find("AV8") then 
		indicators = list_indication(5) .. list_indication(6) -- UFC + ODU
	elseif aircraft:find("JF%-17") then 
		indicators = "-\nlights\n" .. device0:get_argument_value(150) .. device0:get_argument_value(151) .. -- OAP + MRK
			device0:get_argument_value(152) .. device0:get_argument_value(153) .. -- P.U + HNS
			device0:get_argument_value(154) .. device0:get_argument_value(155) .. "\n" .. -- A/P + FPM
			list_indication(3) .. list_indication(4) .. list_indication(5) .. list_indication(6) -- 4 UFC lines
	elseif aircraft:find("SA342") then 
		indicators = "-\ndoppler\n" .. device0:get_argument_value(331) .. "\n" .. -- NADIR doppler mode
			"-\nparameter\n" .. device0:get_argument_value(332) .. "\n" .. -- NADIR selected parameter
			list_indication(3)
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
		if indicators ~= previousIndicators then
			socket.try(iUFCExport.outboundConn:sendto(indicators, iUFCExport.HOST, iUFCExport.OUTBOUND_PORT))
			previousIndicators = indicators
		end
	end

	if PrevExport.LuaExportAfterNextFrame then
		PrevExport.LuaExportAfterNextFrame()
	end
end 

