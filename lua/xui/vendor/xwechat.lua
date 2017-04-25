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
 *
 * xwechat - wechat API
 */
]]

test_msg = "<xml><URL><![CDATA[http://wechat.freeswitch.org.cn/api/wechat]]></URL><ToUserName><![CDATA[seven1240]]></ToUserName><FromUserName><![CDATA[seven1240]]></FromUserName><CreateTime>100</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA[这是一条测试消息]]></Content><MsgId>1</MsgId></xml>"

xwechat = {}

xwechat.access_token = function(realm)
	api = freeswitch.API()
	access_token = api:execute("hash", "select/wechat/wechat_access_token_" .. realm)
	return access_token
end

xwechat.js_ticket = function(realm)
	api = freeswitch.API()
	ticket = api:execute("hash", "select/wechat/js_ticket_" .. realm)
	return ticket
end

xwechat.get_token = function(realm, AppID, AppSec)
	URL = "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=" .. AppID .. "&secret=" .. AppSec
	api = freeswitch.API()

	body = api:execute("curl", URL)
	print(body)
	json = utils.json_decode(body)
	-- print(serialize(list))

	api:execute("hash", "insert/wechat/wechat_access_token_" .. realm .. "/" .. json.access_token)
	return json.access_token
end

xwechat.get_js_ticket = function(realm)
	URL = "https://api.weixin.qq.com/cgi-bin/ticket/getticket?access_token=" .. xwechat.access_token() .. "&type=jsapi"
	api = freeswitch.API()

	body = api:execute("curl", URL)
	json = utils.json_decode(body)
	api:execute("hash", "insert/wechat/wechat_access_token_" .. realm .. "/" .. json.ticket)
	return json.ticket
end

xwechat.get_callback_ip = function(realm)
	URL = "https://api.weixin.qq.com/cgi-bin/getcallbackip?access_token=" .. xwechat.access_token(realm)
	api = freeswitch.API()

	body = api:execute("curl", URL)
	list = utils.json_decode(body)
	print(serialize(list))
end

xwechat.sign = function(realm, nounce, ts, url)
	qs = "jsapi_ticket=" .. xwechat.js_ticket(realm) ..
		"&noncestr=" .. nounce ..
		"&timestamp=" .. ts ..
		"&url=" .. url
	sha1 = require("sha1")
	return sha1(qs)
end

xwechat.create_menu = function(realm, json)
	URL = "https://api.weixin.qq.com/cgi-bin/menu/create?access_token=" .. xwechat.access_token(realm)
	api = freeswitch.API()
	return api:execute("curl", URL .. " post " .. json)
end

xwechat.send_template_msg = function(realm, msg)
	URL = "https://api.weixin.qq.com/cgi-bin/message/template/send?access_token=" .. xwechat.access_token(realm)
	api = freeswitch.API()
	return api:execute("curl", URL .. " post " .. msg)
end

xwechat.get_js_access_token = function(realm, appid, sec, code)
	URL = "https://api.weixin.qq.com/sns/oauth2/access_token?appid=" .. appid .. "&secret=" .. sec .. "&code=" .. code .. "&grant_type=authorization_code"
	api = freeswitch.API()
	return api:execute("curl", URL)
end