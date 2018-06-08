local json = require("json")

l_dbg = l_dbg or DebugServer();
-- print(l_dbg.StartServer)
l_dbg:StartServer(8869);
l_dbg:StartConsole();
function on_tick()
	local msg = l_dbg:Revc();
	if msg then
		t_msg = json.decode(msg);
		if type(t_msg) == "table" and type(t_msg.command) == "string" and t_msg.command ~= "pong" then
			print("debug>", msg);
			if t_msg.command == "continue" then
				local s_response = json.encode(t_msg);
				if s_response then
					l_dbg:Send(s_response);
				end
			elseif t_msg.command == "next" then
				local t_back = {};
				t_back["command"] = "next";
				t_back["seq"] = 0;
				t_back["type"] = "response";
				t_back["arguments"] = t_msg.arguments;
				local s_response = json.encode(t_back);
				print("debug> send: ", s_response)
				l_dbg:Send(s_response);
			end
		end
		-- l_dbg:Send(msg);
	end
	
	local sline = l_dbg:ReadCmd();
	if sline then
		-- print("sline = ", sline)
		-- local _, _, cmd, sline = string.find(sline, "(%w+)(.*)%c$")
		local _, _, cmd, sline = string.find(sline, "(%w+)(.*)")
		-- print(string.format("debug> cmd = %s, sline = %s", cmd or "nil", sline or "nil"));
		-- print(1111, type(cmd), cmd, string.len(cmd), string.len("close"), cmd == "close");
		if cmd then
			if cmd == "dettach" then
				l_dbg:Dettach();
			elseif cmd == "close" then
				-- print("stop")
				l_dbg:StopConsole();
				return 0;
			elseif cmd == "do" then
				if type(sline) == "string" then
					local fun = load(sline);
					if type(fun) == "function" then
						local  errhander = function(e)
							print("debug> error info: "  .. e);
							print("debug> stack info: " .. debug.traceback("current 2 stack: " ,2));
						end
						xpcall(fun, errhander);
					end
				end
			end
		end
	end
	
	return 1;
end

return l_dbg;
