local json = require("json")

local iowrite = io.write

l_dbg = l_dbg or DebugServer();
-- print(l_dbg.StartServer)
l_dbg:StartServer(8869);
l_dbg:StartConsole();
function on_tick()
	local msg = l_dbg:Revc();
	if msg then
		local t_msg = json.decode(msg);
		if type(t_msg) == "table" and type(t_msg.command) == "string" and t_msg.command ~= "pong" then
			print("debug>", msg);
			if t_msg.command == "continue" then
				l_dbg:Send(msg);
			elseif t_msg.command == "next" then
				-- t_msg["point"] = {};
				-- t_msg["point"].path = "file name";
				-- t_msg["point"].line = 56;
				l_dbg:Send(msg);
			elseif t_msg.command == "stack" then
				foo1();
				-- print(1112, straceback)
				t_msg["body"] = straceback;
				local s_msg = json.encode(t_msg);
				if type(s_msg) == "string" then
					l_dbg:Send(s_msg);
				end
				straceback = nil;
				tvariables = nil;
			elseif t_msg.command == "variables" then
				foo1();
				t_msg["body"] = tvariables;
				local s_msg = json.encode(t_msg);
				if type(s_msg) == "string" then
					l_dbg:Send(s_msg);
				end
				straceback = nil;
				tvariables = nil;
			end
		end
		-- l_dbg:Send(msg);

		iowrite("\ndebug> ");
	end
	
	local sline = l_dbg:ReadCmd();
	if sline then
		-- print("sline = ", sline)
		-- local _, _, cmd, sline = string.find(sline, "(%w+)(.*)%c$")
		local _, _, cmd, sparam = string.find(sline, "(%w+)(.*)")
		-- print(string.format("debug> cmd = %s, sline = %s", cmd or "nil", sline or "nil"));
		-- print(1111, type(cmd), cmd, string.len(cmd), string.len("close"), cmd == "close");
		if cmd then
			if cmd == "dettach" then
				l_dbg:Dettach();
			elseif cmd == "close" then
				-- print("stop")
				l_dbg:StopConsole();
				return 0;
			else
				-- if not define command then dostring it
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

			iowrite("\ndebug> ");
		end
	end
	
	return 1;
end

function foo1()
	local a = 1;
	local gdsh = foo2();
	return gdsh;
end

function foo2()
	local b = 1;
	local tz = foo3();
	return tz;
end

function foo3()
	local jsofi = 8978;
	local jgsjoi = 2424;
	local c = 1;
	local func = fooup();
	local sf = func(jgsjoi);
	return sf;
end

function fooup()
	local jsofi = 8978;
	local jgsjoi = 242314;
	local rt = function(poi)
		local d = 1;
		local x = 2;
		local y = 3;
		local z = 4;
		local tb = {};
		tb.s1 = "sf";
		local optk = jgsjoi + 87;
		local s7 = "gsdg";
		local st = foo5();
		return st;
	end
	return rt;
end

function foo5()
	local e = 1;
	straceback = debug.traceback("stack", 2);
	
	local func = debug.getinfo(2, "f").func;
	local index = 1;
	tvariables = {};
	local name, val;
	local count = 1;
	repeat
		name, val = debug.getupvalue(func, count)
		count = count + 1;
		-- print(1111, foo4, "  ", func, "  ", count, name, val)
		if name then
			local stype = type(val);
			local _val = "nil"
			local _type = "string"
			if stype == "table" then
				_type = "object";
				_val = tostring(val);
			elseif stype == "number" then
				_type = "float";
				_val = val;
			else
				_type = "string";
				_val = tostring(val);
			end
			tvariables[index] = {name = name, value = _val, jstype = _type, luatype = "upvalue"};
			-- print(name, _val, _type, stype)
			index = index + 1;
		end
	until not name
	-- print("=======================================")
	
	local count = 1;
	repeat
		name, val = debug.getlocal(2, count)
		count = count + 1;
		-- print(1111, foo4, "  ", func, "  ", count, name, val)
		if name then
			local stype = type(val);
			local _val = "nil"
			local _type = "string"
			if stype == "table" then
				_type = "object";
			elseif stype == "number" then
				_type = "float";
			end
			_val = tostring(val);
			tvariables[index] = {name = name, value = _val, jstype = _type, luatype = "local"};
			-- print(name, _val, _type, stype)
			index = index + 1;
		end
	until not name
end

iowrite("\ndebug> ");
return l_dbg;
