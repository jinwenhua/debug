local dbg = DebugServer();
-- print(dbg.StartServer)
dbg:StartServer(8869);
-- dbg:StartConsole();
function on_tick()
	local msg = dbg:Revc();
	if msg then
		-- print("debug>", msg);
		-- dbg:Send(msg);
	end
	
	local sline = dbg:ReadCmd();
	if sline then
		-- print("sline = ", sline)
		-- local _, _, cmd, sline = string.find(sline, "(%w+)(.*)%c$")
		local _, _, cmd, sline = string.find(sline, "(%w+)(.*)")
		-- print(string.format("debug> cmd = %s, sline = %s", cmd or "nil", sline or "nil"));
		-- print(1111, type(cmd), cmd, string.len(cmd), string.len("close"), cmd == "close");
		if cmd then
			if cmd == "dettach" then
				dbg:Dettach();
			elseif cmd == "close" then
				-- print("stop")
				dbg:StopConsole();
				return 0;
			end
		end
	end
	
	return 1;
end


