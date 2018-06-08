print("debug> do update")
local json = require("json")
local t_msg = {};
t_msg["command"] = "onbreak";
t_msg["seq"] = 0;
t_msg["type"] = "response";
t_msg["point"] = {};
t_msg["point"].path = "E:\\github\\document\\study\\lua\\a_start_search_v4_1.lua";
t_msg["point"].line = 46;
local msg = json.encode(t_msg);
-- print("debug> msg = ", type(msg))
if type(msg) == "string" then
	-- print("debug> l_dbg = ", type(l_dbg))
	l_dbg:Send(msg);
	print("debug> ", msg)
end


