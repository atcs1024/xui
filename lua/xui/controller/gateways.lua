--[[
/*
 * HTML5 GUI Framework for FreeSWITCH - XUI
 * Copyright (C) 2015-2017, Seven Du <dujinfang@x-y-t.cn>
 *
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is XUI - GUI for FreeSWITCH
 *
 * The Initial Developer of the Original Code is
 * Seven Du <dujinfang@x-y-t.cn>
 * Portions created by the Initial Developer are Copyright (C)
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Seven Du <dujinfang@x-y-t.cn>
 * Mariah Yang <yangxiaojin@x-y-t.cn>
 *
 *
 */
]]

xtra.start_session()
xtra.require_login()

content_type("application/json")
require 'xdb'
xdb.bind(xtra.dbh)
require 'm_gateway'
require 'm_user'

--unreg must before reg
function get_gateway_action(action)
	if string.find(action, "start") then
		return "startgw"
	elseif string.find(action, "stop") then
		return "killgw"
	elseif string.find(action, "unreg") then
		return "unregister"
	elseif string.find(action, "reg") then
		return "register"
	end

	return "err"
end

function gateway_status(name)
	local api = freeswitch.API()
	local args = "xmlstatus gateway " .. name
	local doc = require("xmlSimple").newParser()
	local ret = api:execute("sofia", args)
	local data = string.gsub(ret:gsub("-", "_"), "(</?)name(>)", "%1gateway_name%2")
	local xml = doc:ParseXmlText(data)
	local stauts = {}

	if xml and xml.gateway then
		stauts.gateway_state = xml.gateway.state:value()
		stauts.gateway_status = xml.gateway.status:value()
	end
	return stauts
end

function xml2tab(data, _all_)
	local gws = string.gsub(data:gsub("-", "_"), "(</?)name(>)", "%1gateway_name%2")
	local doc = require("xmlSimple").newParser()
	local xml = doc:ParseXmlText(gws)

	if _all_ == "all" then
		local gateways = {}
		if #xml.gateways.gateway == 0 and xml.gateways.gateway then
			local gateway = {}
			gateway.name = xml.gateways.gateway.gateway_name:value()
			gateway.gateway_state = xml.gateways.gateway.state:value()
			gateway.gateway_status = xml.gateways.gateway.status:value()
			table.insert(gateways, gateway)
		elseif #xml.gateways.gateway > 0 then
			for i = 1, #xml.gateways.gateway do
				local gateway = {}
				gateway.name = xml.gateways.gateway[i].gateway_name:value()
				gateway.gateway_state = xml.gateways.gateway[i].state:value()
				gateway.gateway_status = xml.gateways.gateway[i].status:value()

				table.insert(gateways, gateway)
			end
		end
		return gateways
	else
		local gateway = {}

		if xml and xml.gateway then
			gateway.name = xml.gateway.gateway_name:value()
			gateway.profile_name = xml.gateway.profile:value()
			gateway.scheme = xml.gateway.scheme:value()
			gateway.realm = xml.gateway.realm:value()
			gateway.username = xml.gateway.username:value()
			gateway.register_password = xml.gateway.password:value()
			gateway.from = xml.gateway.from:value()
			gateway.to = xml.gateway.to:value()
			gateway.contact = xml.gateway.contact:value()
			gateway.exten = xml.gateway.exten:value()
			gateway.proxy = xml.gateway.proxy:value()
			gateway.context = xml.gateway.context:value()
			gateway.expires = xml.gateway.expires:value()
			gateway.freq = xml.gateway.freq:value()
			gateway.ping = xml.gateway.ping:value()
			gateway.ping_freq = xml.gateway.pingfreq:value()
			gateway.ping_min = xml.gateway.pingmin:value()
			gateway.ping_count = xml.gateway.pingcount:value()
			gateway.ping_max = xml.gateway.pingmax:value()
			gateway.ping_time = xml.gateway.pingtime:value()
			gateway.pinging = xml.gateway.pinging:value()
			gateway.state = xml.gateway.state:value()
			gateway.status = xml.gateway.status:value()
			gateway.uptime_usec = xml.gateway.uptime_usec:value()
			gateway.calls_in = xml.gateway.calls_in:value()
			gateway.calls_out = xml.gateway.calls_out:value()
			gateway.failed_calls_in = xml.gateway.failed_calls_in:value()
			gateway.failed_calls_out = xml.gateway.failed_calls_out:value()
		end
		return gateway
	end
end

-- action:reg/unreg
function control_gateway(profile_name, action, gateway_name)
	action = get_gateway_action(action)
	local api = freeswitch.API()
	local args = "profile " .. profile_name .. " " .. action .. " " .. gateway_name
	freeswitch.consoleLog("debug", "sofia args:" .. args .. "\n")
	api:execute("sofia", args)
end

get('/', function(params)
	if not m_user.has_permission() then
		return "[]"
	end

	n, gateways = xdb.find_all("gateways")

	if (n > 0) then
		for k,v in ipairs(gateways) do
			gateways[k].password = nil
		end

		return gateways
	else
		return "[]"
	end
end)

get('/list',function(params)
	api = freeswitch.API()
	if params.request and params.request.name then
		gateway = xdb.find_one("gateways", {name = params.request.name})
		if gateway then
			args = "xmlstatus gateway " ..  params.request.name
			print(args)

			ret = api:execute("sofia", args)
			if ret then
				local data = xml2tab(ret, nil)
				if next(data)  then
					data.id = gateway.id
					data.description = gateway.description
					data.password = gateway.password
					data.register = gateway.register
					data.profile_id = gateway.profile_id
					data.created_at = gateway.created_at
					data.updated_at = gateway.updated_at
					data.deleted_at = gateway.deleted_at
					return 200, {code = 200, text = data}
				else
					return 200, {code = 484, text = "Invalid Gateway!"}
				end
			else
				return 200, {code = 484, text="Invalid Gateway!"}
			end
		else
			return 200, {code = 404, text="Gateway Not Found"}
		end
	else
		args = "xmlstatus gateway"
		print(args)
		ret = api:execute("sofia", args)
		local data = xml2tab(ret, "all")
		return 200, {code = 200, text = data}
	end
end)

get('/:id', function(params)
	gw = xdb.find("gateways", params.id)
	if gw then
		gw.password = nil
		p_params = m_gateway.params(params.id)
		gw.params = p_params
		return gw
	else
		return 404
	end
end)

get('/name/:name',function(params)
	gateway = xdb.find_one("gateways", {name = params.name})
	if gateway then
		api = freeswitch.API()
		args = "xmlstatus gateway"  .. ' ' ..  params.name
		print(args)

		ret = api:execute("sofia", args)
		return ret
	else 
		return 404
	 end
end)

get('/verify/:username/:number',function(params)
	gateway = xdb.find_one("gateways", {username = params.username})        
	if gateway then
		api = freeswitch.API()
		args = "[leg_timeout=10]sofia/gateway/" .. params.username .. "/010" .. params.number .. " " .. "&playback(silence_stream://20000)"

		ret = api:execute("originate", args)

		local s = 0
		local result = 0

		while s < 10 do
			result = api:execute("hash","select/qyq/" .. params.number)
				if not (result == "") then
					break
				end
			s = s + 1
			freeswitch.msleep(1000) 
		end
		print(result)

		if result == params.username then
			api:execute("hash", "delete/qyq/" .. params.number)
			return 200, {code = 200, text="OK"}
		else
			return 500, {code = 500, text="ERROR"}
		end
	else
		return 404, {code = 404, text="NOT FOUND"}
	end
end)

post('/', function(params)
	ret = m_gateway.create(params.request)

	if ret then
		return {id = ret}
	else
		return 500, "{}"
	end
end)

post('/:ref_id/params/', function(params)
	params.request.ref_id = params.ref_id
	params.realm = 'gateway'
	params.request.realm = params.realm
	ret = m_gateway.createParam(params.request)

	if ret then
		return {id = ret}
	else
		return 500, "{}"
	end
end)


put('/verify',function(params)
	local number = params.request.number
	local gateway_name = params.request.username

	params.request.name = gateway_name
	params.request.register = "yes"

	params.request.number = nil

	freeswitch.consoleLog("debug", "verify:" .. serialize(params.request))

	gw_id = m_gateway.create(params.request)

	if gw_id then
		gateway = xdb.find("gateways", gw_id)
		if gateway then
			profile = xdb.find("sip_profiles", gateway.profile_id)
			profile_name = profile.name or "public"

			api = freeswitch.API()
			control_gateway(profile_name, "startgw", gateway_name)

			local waiting_startgw = 10
			local doc = require("xmlSimple").newParser()
			local reged = false

			while waiting_startgw > 0 do
				freeswitch.consoleLog("debug", "waiting_reg waiting_reg waiting_reg !!!\n")
				local data = api:execute("sofia", "xmlstatus gateway " .. gateway_name)

				data = string.gsub(data, "name", "gateway_name")

				local xml = doc:ParseXmlText(data)

				if xml and xml.gateway and xml.gateway.state:value() == "REGED" and xml.gateway.status:value() == "UP" then
					reged = true
					freeswitch.consoleLog("debug", "verify id " .. gateway_name .. " reged!!!")
					break
				end

				waiting_startgw = waiting_startgw - 1
				freeswitch.msleep(1000)
			end

			if not reged then
				m_gateway.delete(gw_id)
				return 200, {code = 403, text = "gateway reg failed"}
			end

			control_gateway(profile_name, "killgw", gateway_name)
			freeswitch.msleep(2000)

			m_gateway.delete(gw_id)

			return 200, {code = 200, text = "gateway verify success"}
		else
			return 200, {code = 404, text = "gateway not found"}
		end
	else
		return 200, {code = 503, text = "create gateway failed"}
	end
end)

put('/verify1',function(params)
	local number = params.request.number
	local gateway_name = params.request.username

	params.request.name = gateway_name
	params.request.register = "yes"

	params.request.number = nil

	freeswitch.consoleLog("debug", "verify:" .. serialize(params.request))

	gw_id = m_gateway.create(params.request)

	if gw_id then
		gateway = xdb.find("gateways", gw_id)
		if gateway then
			profile = xdb.find("sip_profiles", gateway.profile_id)
			profile_name = profile.name or "public"

			api = freeswitch.API()
			control_gateway(profile_name, "startgw", gateway_name)

			local waiting_startgw = 10
			local doc = require("xmlSimple").newParser()
			local reged = false

			while waiting_startgw > 0 do
				freeswitch.consoleLog("debug", "waiting_reg waiting_reg waiting_reg !!!\n")
				local data = api:execute("sofia", "xmlstatus gateway " .. gateway_name)

				data = string.gsub(data, "name", "gateway_name")

				local xml = doc:ParseXmlText(data)

				if xml and xml.gateway and xml.gateway.state:value() == "REGED" and xml.gateway.status:value() == "UP" then
					reged = true
					freeswitch.consoleLog("debug", "verify id " .. gateway_name .. " reged!!!")
					break
				end

				waiting_startgw = waiting_startgw - 1
				freeswitch.msleep(1000)
			end

			if not reged then
				m_gateway.delete(gw_id)
				return 200, {code = 403, text = "reg failed"}
			end

			-- call oneself
			dial_args = "[leg_timeout=10]sofia/gateway/" .. gateway_name .. "/010" .. number .. " " .. "&playback(silence_stream://20000)"

			freeswitch.consoleLog("debug", "verify dial_args:" .. dial_args .. "\n")

			api:execute("originate", dial_args)

			local waiting_call = 10
			local result = 0

			while waiting_call > 0 do
				freeswitch.consoleLog("debug", "waiting_call waiting_call waiting_call !!!\n")
				result = api:execute("hash", "select/qyq/" .. number)

				if result and result ~= "" then
					break
				end
				waiting_call = waiting_call - 1
				freeswitch.msleep(1000)
			end

			control_gateway(profile_name, "killgw", gateway_name)
			freeswitch.msleep(2000)

			m_gateway.delete(gw_id)

			if result == gateway_name then
				freeswitch.consoleLog("info", "verify number matched!!!")
				api:execute("hash", "delete/qyq/" .. number)
				return 200, {code = 200, text = "OK"}
			else
				freeswitch.consoleLog("ERR", "verify id:" .. gateway_name .. ",real id:" .. result .. "\n")
				return 200, {code = 406, text = "verify number not matched"}
			end
		else
			return 200, {code = 404, text = "gateway not found"}
		end
	else
		return 200, {code = 503, text = "create gateway failed"}
	end
end)

-- reg/unreg/start/stop
put('/control', function(params)
	action = params.request.action

	gateway = xdb.find_one("gateways", {name = params.request.name})
	if gateway then
		profile = xdb.find("sip_profiles", gateway.profile_id)
		profile_name = profile.name or 'public'
		api = freeswitch.API()

		status = gateway_status(gateway.name)

		if not next(status) then
			if string.find(action, "unreg") then
				return 200, {code = 500, text = "Gateway Not Start"}
			elseif string.find(action, "reg") then
				control_gateway(profile_name, "startgw", gateway.name)
			else
				control_gateway(profile_name, action, gateway.name)
			end
		else
			gateway_status = status.gateway_status
			gateway_state = status.gateway_state

			if gateway_status == "DOWN" then
				if string.find(action, "unreg") then
					return 200, {code = 500, text = "Gateway Not Start"}
				elseif string.find(action, "reg") then
					control_gateway(profile_name, "startgw", gateway.name)
				else
					control_gateway(profile_name, action, gateway.name)
				end

			elseif gateway_status == "UP" then
				if gateway_state == "REGED" then
					if string.find(action, "unreg") then
						control_gateway(profile_name, "unregister", gateway.name)
					elseif string.find(action, "reg") then
						return 200, {code = 200, text = "Gateway Has Reged!"}
					else
						control_gateway(profile_name, action, gateway.name)
					end
				else
					if string.find(action, "unreg") then
						return 200, {code = 200, text = "Gateway Has Unreged!"}
					elseif string.find(action, "reg") then
						control_gateway(profile_name, "register", gateway.name)
					else
						control_gateway(profile_name, action, gateway.name)
					end
				end
			end
		end
		return 200, {code = 200, text = "OK"}
	else
		return 200, {code = 404, text = "Gateway Not Found"}
	end
end)

put('/:id', function(params)
	print(serialize(params))
	ret = xdb.update("gateways", params.request)
	if ret then
		return 200, "{}"
	else
		return 500
	end
end)

put('/control/gateways/:name', function(params)
	gateway = xdb.find_one("gateways", {name = params.name})
	action = params.request.action

	if gateway then

		profile = xdb.find("sip_profiles", gateway.profile_id)
		profile_name = profile.name or 'public'

		api = freeswitch.API()
		args = "profile " .. profile_name .. ' ' .. action .. ' ' .. params.name

		print(args)

		ret = api:execute("sofia", args)

			return "200"
	else
		return "404"
	end
end)

put('/:id/params/:param_id', function(params)
	print(serialize(params))
	ret = nil;

	if params.request.action and params.request.action == "toggle" then
		ret = m_gateway.toggle_param(params.id, params.param_id)
	else
		ret = m_gateway.update_param(params.id, params.param_id, params.request)
	end

	if ret then
		return ret
	else
		return 404
	end
end)

put('/:id/control', function(params)
	print(utils.serialize(params))

	gateway = xdb.find("gateways", params.id)
	action = params.request.action

	if gateway then
		profile = xdb.find("sip_profiles", gateway.profile_id)
		profile_name = profile.name or 'public'

		api = freeswitch.API()
		args = "profile " .. profile_name .. ' ' .. action .. ' ' .. gateway.name

		print(args)

		ret = api:execute("sofia", args)

			return "200"
	else
		return "404"
	end
end)

delete('/:id', function(params)
	gateway = xdb.find("gateways", params.id)
	api = freeswitch.API()
	args = "xmlstatus gateway " ..  gateway.name
	ret = api:execute("sofia", args)

	if ret:match("^%Invalid Gateway!") then
		ret = m_gateway.delete(params.id)
		if ret >= 0 then
			return 200, {code = 200, text="OK"}
		else
			return 500, {code = 500, text="ERR"}
		end
	else
		return 404, {code = 404, text="RUNNING NOT STOP"}
	end
end)

delete('/:id/param/:param_id', function(params)
	id = params.id
	param_id = params.param_id
	ret = m_gateway.delete_param(id, param_id)

	if ret >= 0 then
		return 200, "{}"
	else
		return 500, "{}"
	end
end)
