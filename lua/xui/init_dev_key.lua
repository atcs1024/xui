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
 * MariahYang <yangxiaojin@x-y-t.cn>
 * Portions created by the Initial Developer are Copyright (C)
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * MariahYang <yangxiaojin@x-y-t.cn>
 *
 *
 */
]]

local cur_dir = debug.getinfo(1).source;
cur_dir = string.gsub(cur_dir, "^@(.+)/init_dev_key.lua$", "%1")

package.path = package.path .. ";/etc/xtra/?.lua"
package.path = package.path .. ";" .. cur_dir .. "/?.lua"
package.path = package.path .. ";" .. cur_dir .. "/vendor/?.lua"
package.path = package.path .. ";" .. cur_dir .. "/model/?.lua"

require 'xdb'
require 'xtra_config'
require 'utils'

if config.db_auto_connect then xdb.connect(config.dsn) end

function init_hash_key()
	n, keys = xdb.find_by_cond("user_dev_key")
	if n >= 1 then
		local api = freeswitch.API()
		for i = 1, #keys do
			api:execute("hash", "insert/xui/" .. keys[i].key .. "/" .. keys[i].user_id)
		end
	end
end

init_hash_key()
