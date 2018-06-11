print("debug> do update")
local json = require("json")
local t_msg = {};
t_msg["command"] = "onbreak";
t_msg["seq"] = 0;
t_msg["type"] = "response";
t_msg["point"] = {};
t_msg["point"].path = "e:\\github\\vscode-l-debug\\script\\a_start_search.lua";
t_msg["point"].line = 308;
local msg = json.encode(t_msg);
-- print("debug> msg = ", type(msg))
if type(msg) == "string" then
	-- print("debug> l_dbg = ", type(l_dbg))
	l_dbg:Send(msg);
	print("debug> ", msg)
end
