--[[
@ lua debug for vs code
@
@ Author luhengsi 
@ Mail   luhengsi@163.com
@ Date   2018-06-10
@
@ please check Licence.txt file for licence and legal issues. 
]]
local sformat = string.format;
local sfind = string.find;
local strlen = string.len;
local ssub = string.sub;
local sgsub = string.gsub;
local sgmatch = string.gmatch;
local slower = string.lower;
local dsethook = debug.sethook;
local gethook = debug.gethook;
local dgetinfo = debug.getinfo;
local dtraceback = debug.traceback;
local dgetupvalue = debug.getupvalue;
local dgetlocal = debug.getlocal;
local tinsert = table.insert
local tconcat = table.concat;
local fxpcall = xpcall;

require("ldebugserver");
l_dbg = l_dbg or DebugServer();
l_debug = l_debug or require("ldebug");
ldb_json = ldb_json or require("json");
ldb_mrg = ldb_mrg or {};

function ldb_mrg:on_tick(mode)
	if not mode and l_debug.mode == l_debug.DEBUG_MODE_WAIT then
		return;
	end
	self:proccess_msg();
	self:proccess_io();
end

function ldb_mrg:init(port, bconsole)
	l_debug:set_io_fuc(nil, nil)

	port = port or 8869;
	l_dbg:StartServer(port);

	bconsole = bconsole or 0;
	if bconsole == 1 then
		l_dbg:StartConsole();
	end

	self.straceback = self.straceback or nil;
	self.tvariables = self.tvariables or nil;
end

function ldb_mrg:run()
	self.isrunning = true;
	l_dbg:StartConsole();
	while self.isrunning do 
		self:on_tick();
		self:sleep(100);
	end
end

function ldb_mrg:stop()
	self.isrunning = false;
	l_dbg:StopConsole();
end

function ldb_mrg:add_break_point(file_name, line_no)
    l_debug:add_break_point_by_info(file_name, line_no);
end

function ldb_mrg:set_current_stack(straceback)
	if type(straceback) == "string" then
		self.straceback = straceback;
	else
		self.straceback = nil;
	end
end

function ldb_mrg:set_current_variables(tvariables)
	if type(tvariables) == "table" then
		self.tvariables = tvariables;
	else
		self.tvariables = nil;
	end
end

function ldb_mrg:updatestackinfo(nlevel)
	nlevel = nlevel or 2;
	nlevel = nlevel + 1;
	local e = 1;
	self.straceback = dtraceback("stack", nlevel);
	local func = dgetinfo(nlevel, "f").func;
	local index = 1;
	self.tvariables = nil;
	local name, val;
	-- local count = 1;
	-- repeat
		-- name, val = dgetupvalue(func, count)
		-- count = count + 1;
		-- if name then
			-- local stype = type(val);
			-- local _type = "string"
			-- if stype == "table" then
				-- _type = "object";
			-- elseif stype == "number" or stype == "string" then
				-- _type = "float";
				-- _val = tostring(val);--self:copy_no_loop(val);
				-- self.tvariables = self.tvariables or {}
				-- self.tvariables[index] = {name = name, value = _val, jstype = _type, luatype = "upvalue"};
				-- index = index + 1;
			-- elseif stype == "nil" then
				-- val = "nil";
			-- end
		-- end
	-- until not name
	
	local count = 1;
	repeat
		name, val = dgetlocal(nlevel, count)
		count = count + 1;
		if name then
			local stype = type(val);
			local _type = "string"
			if stype == "table" then
				_type = "object";
			elseif stype == "number" then
				_type = "float";
				_val = tostring(val);--self:copy_no_loop(val);
				self.tvariables = self.tvariables or {}
				self.tvariables[index] = {name = name, value = _val, jstype = _type, luatype = "local"};
				index = index + 1;
			elseif stype == "string" then
				_val = tostring(val);--self:copy_no_loop(val);
				self.tvariables = self.tvariables or {}
				self.tvariables[index] = {name = name, value = _val, jstype = _type, luatype = "local"};
				index = index + 1;
			elseif stype == "nil" then
				val = "nil";
			end
		end
	until not name
end

function ldb_mrg:send_match_break_point(file_name, line_no)
	if type(file_name) ~= "string" or type(line_no) ~= "number" then
		return;
	end
	local t_msg = {};
	t_msg["command"] = "onbreak";
	t_msg["seq"] = 0;
	t_msg["type"] = "response";
	t_msg["point"] = {};
	t_msg["point"].path = file_name;
	t_msg["point"].line = line_no;
	local msg = self:encode(t_msg);
	if type(msg) == "string" then
		l_dbg:Send(msg);
	end
end

function ldb_mrg:sleep(millis)
	l_dbg:slee(millis);
end

function ldb_mrg:copy_no_loop(value, max_deep, max_count)
	local value_cach = {};
	local v_copy = nil;
	local deep = 0;
	max_deep = max_deep or 4;
	max_count = max_count or 8;
	function _copy_no_loop(value)
		deep = deep + 1;
        local value_type = type(value);
        if value_type == "table" then
			if value_cach[value] or deep >= max_deep  then
				deep = deep - 1;
                return tostring(value);
            end

			local t_temp = {};
			value_cach[value] = 1;
			local count = 0;
			for k, v in pairs(value) do 
				count = count + 1;
				t_temp[k] = _copy_no_loop(v);
				if count >= max_count then
					break;
				end
			end
			deep = deep - 1;
			return t_temp;
        elseif value_type == "number" then
            return value;
		elseif value_type == "string" then
			if strlen(value) > 64 then
				value = ssub(value, 1, 64);
			end
            return value;
        end
		return tostring(value);
    end
    v_copy = _copy_no_loop(value);
    return v_copy;
end


function ldb_mrg:encode(t_msg)
	local ok, msg = self:pcall(ldb_json.encode, t_msg);
	if ok and type(msg) == "string" then
		return msg;
	end

	return nil;
end

function ldb_mrg:decode(msg)
	local ok, t_msg = self:pcall(ldb_json.decode, msg);
	if ok and type(t_msg) == "table" then
		return t_msg;
	end

	return nil;
end

function ldb_mrg:pcall(func, ...)
    local errhander = function(e)
        print("debug> error info: "  .. e);
        print("debug> stack info: " .. dtraceback("current 2 stack: " ,2));
    end

    return fxpcall(func, errhander, ...);
end
--===================proccess client message========================================
function ldb_mrg:add_io_handler(command, fhandler)
    self.io_handler_map = self.io_handler_map or {};
    self.io_handler_map[command] = fhandler;
end

function ldb_mrg:proccess_io()
	local sline = l_dbg:ReadCmd();
	if type(sline) == "string" then
		local _, _, command, sparam = sfind(sline, "(%w+)(.*)")
        if type(command) == "string" then
			self.io_handler_map = self.io_handler_map or {};
			local fhandler = self.io_handler_map[command];
			if type(fhandler) == "function" then
				ldb_mrg:pcall(fhandler, self, sparam);
			else
				if l_debug.mode ~= l_debug.DEBUG_MODE_WAIT then
					-- if not define command then dostring it
					self:io_on_default(sline);
				end
			end
		end
    end
    
    return 1;
end

function ldb_mrg:io_on_dettach(sparam)
    l_dbg:Dettach();
end
ldb_mrg:add_io_handler("dettach", ldb_mrg.io_on_dettach);

function ldb_mrg:io_on_close(sparam)
	l_dbg:StopConsole();
end
ldb_mrg:add_io_handler("close", ldb_mrg.io_on_close);

function ldb_mrg:io_on_default(sline)
	local fun = load(sline);
	if type(fun) == "function" then
		ldb_mrg:pcall(fun);
	end
end


--===================proccess client message========================================
function ldb_mrg:add_msg_handler(command, fhandler)
    self.msg_handler_map = self.msg_handler_map or {};
    self.msg_handler_map[command] = fhandler;
end

function ldb_mrg:set_msg_cach(command, info)
	self.msg_cach_map = self.msg_cach_map or {};
	self.msg_cach_map[command] = info;
end

function ldb_mrg:get_msg_cach(command)
	self.msg_cach_map = self.msg_cach_map or {}
	return self.msg_cach_map[command];
end

function ldb_mrg:proccess_msg()
	local msg = l_dbg:Revc();
	if type(msg) == "string" then
		local t_msg = self:decode(msg);
		if t_msg and type(t_msg.command) == "string" then
			if t_msg.command ~= "pong" then
				print("debug>", msg)
			end
            self.msg_handler_map = self.msg_handler_map or {};
            local fhandler = self.msg_handler_map[t_msg.command];
            if type(fhandler) == "function" then
                self:pcall(fhandler, self, t_msg, msg);
            end
		end
	end
end

function ldb_mrg:msg_on_pong(t_msg, msg)

end
ldb_mrg:add_msg_handler("pong", ldb_mrg.msg_on_pong);

function ldb_mrg:msg_on_continue(t_msg, msg)
	l_debug:set_mode(l_debug.DEBUG_MODE_RUN);
	l_dbg:Send(msg);
end
ldb_mrg:add_msg_handler("continue", ldb_mrg.msg_on_continue);

function ldb_mrg:send_next_cach(tparam)
	local info = self:get_msg_cach("next");
	if not info then
		return;
	end
	self:set_msg_cach("next", nil);
	if tparam then
		local t_msg = info.t_msg;
		t_msg["point"] = {};
		t_msg["point"].path = tparam.path;
		t_msg["point"].line = tparam.line;
		local msg = self:encode(t_msg);
		if msg then
			l_dbg:Send(msg);
		end
	else
		l_dbg:Send(info.msg);
	end
end

function ldb_mrg:msg_on_next(t_msg, msg)
	l_debug:set_mode(l_debug.DEBUG_MODE_NEXT);
	local info = {};
	info.t_msg = t_msg;
	info.msg = msg;
	self:set_msg_cach(t_msg.command, info);
end
ldb_mrg:add_msg_handler("next", ldb_mrg.msg_on_next);

function ldb_mrg:msg_on_stack(t_msg, msg)
	t_msg["body"] = self.straceback;
	local s_msg = self:encode(t_msg);
	if s_msg then
		l_dbg:Send(s_msg);
	end
	-- self.straceback = nil;
end
ldb_mrg:add_msg_handler("stack", ldb_mrg.msg_on_stack);

function ldb_mrg:msg_on_variables(t_msg, msg)
	t_msg["body"] = self.tvariables;
	local s_msg = self:encode(t_msg);
	if type(s_msg) == "string" then
		-- print(99999, s_msg);
		l_dbg:Send(s_msg);
	end
	-- self:set_current_variables(nil)
end
ldb_mrg:add_msg_handler("variables", ldb_mrg.msg_on_variables);

function ldb_mrg:msg_on_clearpoints(t_msg, msg)
	local file_name = t_msg["arguments"];
	if type(file_name) == "string" then
		l_debug:clear_break_point(file_name)
	end
end
ldb_mrg:add_msg_handler("clearpoints", ldb_mrg.msg_on_clearpoints);

function ldb_mrg:msg_on_setbreakpoints(t_msg, msg)
	local file_name = t_msg["path"];
	local lines = t_msg["lines"] or {};
	if type(file_name) == "string" then
		for _, line_no in pairs(lines) do 
			l_debug:add_break_point_by_info(file_name, line_no, 1);
		end
	end
end
ldb_mrg:add_msg_handler("setbreakpoints", ldb_mrg.msg_on_setbreakpoints);

function ldb_mrg:msg_on_hover(t_msg, msg)
	local t_body = t_msg["body"] or {};
	local var_name = t_body["name"];
	local sfunc = sformat([[return %s]], var_name);
	local fun = load(sfunc);
	if type(fun) == "function" then
		local ok, var = self:pcall(fun);
		if ok then
			t_msg["body"] = t_body;
			var = self:copy_no_loop(var);
			t_body["value"] = var;
			local s_msg = self:encode(t_msg);
			if s_msg then
				l_dbg:Send(s_msg);
			end
		end
	end
end
ldb_mrg:add_msg_handler("hover", ldb_mrg.msg_on_hover);

return ldb_mrg;
