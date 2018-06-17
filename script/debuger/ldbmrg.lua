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
local slower = string.lower;
local dgetinfo = debug.getinfo;
local tinsert = table.insert
local tconcat = table.concat;
local mfloor = math.floor;
local mfmod = math.fmod;

require("ldebugserver");
l_dbg = l_dbg or DebugServer();
l_debug = l_debug or require("ldebug");
ldb_json = ldb_json or require("json");
ldb_mrg = ldb_mrg or {};

ldb_mrg.workingPath = ldb_mrg.workingPath or "e:\\github\\vscode-l-debug\\";

ldb_mrg.FILER_FILE = 
{
	["json"] = 1,
	["init"] = 1,
	["ldbmrg"] = 1,
	["protocol"] = 1,
	["utilty"] = 1,
};

function ldb_mrg:on_tick(mode)
	if not mode and l_debug.mode == l_debug.DEBUG_MODE_WAIT then
		return;
	end
	self:proccess_msg();
	self:proccess_io();
end

function ldb_mrg:run()
	self.isrunning = true;
	l_dbg:StartConsole();
	print("now debuger is running.")
	while self.isrunning do 
		self:on_tick();
		self:sleep(100);
	end
end

function ldb_mrg:init(port, bconsole)
	print("ldb_mrg init.")
	l_debug:set_io_fuc(nil, nil)

	port = port or 8869;
	l_dbg:StartServer(port);

	bconsole = bconsole or 0;
	if bconsole == 1 then
		l_dbg:StartConsole();
	end
	
	local info = dgetinfo(1, "S");
	local s_source = info["source"];
	local path = l_utily:win_style_path(s_source);
	local _, _, dir = sfind(path, "(%w+)\\.*.lua");
	self.this_file_dir = dir or '';
	self.debug_filter_list = {};
	for name, _ in pairs(self.FILER_FILE) do 
		local filter_path = sformat("%s\\%s.lua", self.this_file_dir, name);
		self.debug_filter_list[filter_path] = 1;
	end

	-- print(999, dir)
	l_debug:init();
	l_socket:init();
end

function ldb_mrg:restart()
	l_debug:release();
	l_socket:init();
end

function ldb_mrg:stop()
	self:restart();
	self.isrunning = false;
	l_dbg:StopConsole();
	l_socket:terminated();
	local tick = 0;
	while tick <= 20 do
		if mfmod(tick, 10) == 0 then
			local second = mfloor(tick / 10);
			print(sformat("debug> debug server exit in %s seconds.", 2 - second));
		end
		tick = tick + 1;
		self:on_tick();
		self:sleep(100);
	end
end

function ldb_mrg:add_break_point(file_name, line_no)
    l_debug:add_break_point(file_name, line_no);
end

function ldb_mrg:set_break_points(path, lines)
	return l_debug:set_break_points(path, lines);
end

function ldb_mrg:stop_on_breakpoint()
	l_socket:stop_on_event("breakpoint")
end

function ldb_mrg:stop_on_step()
	l_socket:stop_on_event("step")
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
	local msg = l_utily:encode(t_msg);
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

function ldb_mrg:get_stack_trace()
	local straceback = l_debug:get_stack_info();

	local tlist = l_utily:split(straceback, "%c");
	
	local count = 0;
	local tstackframes = {};
	local tbody = {};
	for _, sline in ipairs(tlist) do 
		local _, _, path, snum, sfunc = sfind(sline, "(%w.*%w+):(%d+): in (.*)");
		if path and snum and sfunc then
			local _, _, name = sfind(path, "(%w+.lua)");
			name = name or path;
			local filter_name = sformat("%s\\%s", self.this_file_dir, name);
			if not self.debug_filter_list[filter_name] then
				-- print(path, name, snum, sfunc);
				path = slower(path);
				local tsource = {};
				tsource["path"] = self.workingPath..path;
				tsource["name"] = name;
				tsource["sourceReference"] = 0;
				tsource["adapterData"] = "debug-server-data";
				local info = {};
				info["id"] = count;
				info["source"] = tsource;
				info["line"] = tonumber(snum);
				info["name"] = sfunc;
				info["column"] = 0;
				count = count + 1;
				tstackframes[count] = info;
			end
		end
	end
	
	tbody["stackFrames"] = tstackframes;
	tbody["totalFrames"] = count;
	
	return tbody;
end

function ldb_mrg:_get_normal_veriables(tget, tvariables)
	local count = 0;
	for name, value in pairs(tvariables) do 
		local tinfo = {};
		local stype = type(value);
		if stype == "string" then
			tinfo["type"] = "string";
		elseif stype == "number" then
			tinfo["type"] = "float";
		end
		if tinfo["type"] then
			count = count + 1;
			tinfo["name"] = tostring(name);
			tinfo["value"] = tostring(value);
			tinfo["variablesReference"] = 0;
			tget[count] = tinfo;
		end
	end
	return tget;
end

function ldb_mrg:get_normal_veriables()
	local tupvalues = l_debug:get_upvalue_info();
	local tlocals = l_debug:get_local_info();
	local tbody = {};
	tbody["variables"] = {};
	self:_get_normal_veriables(tbody["variables"], tupvalues);
	self:_get_normal_veriables(tbody["variables"], tlocals);
	return tbody;
end

function ldb_mrg:_get_object_veriables(tget, tvariables)
	self.var_ref_list = self.var_ref_list or {};
	local index = #(self.var_ref_list);
	local count = 0;
	tget = tget or {};
	for name, value in pairs(tvariables) do 
		if type(value) == "table" then
			count = count + 1;
			index = index + 1;
			local info = {};
			info["name"] = tostring(name);
			info["value"] = "table";
			info["type"] = "object";
			info["variablesReference"] = index;
			tget[count] = info;

			self.var_ref_list[index] = value;
		end
	end

	return tget;
end

function ldb_mrg:get_object_veriables()
	local tupvalues = l_debug:get_upvalue_info();
	local tlocals = l_debug:get_local_info();
	local tbody = {};
	tbody["variables"] = {};
	self:_get_object_veriables(tbody["variables"], tupvalues);
	self:_get_object_veriables(tbody["variables"], tlocals);
	return tbody;
end

function ldb_mrg:get_single_object(ref_id)
	self.var_ref_list = self.var_ref_list or {};
	local tvalue = self.var_ref_list[ref_id];
	local index = #(self.var_ref_list);
	local count = 0;
	local body = {}
	body.variables = {};
	if type(tvalue) == "table" then
		for name, value in pairs(tvalue) do 
			local stype = type(value);
			local info = {};
			info["name"] = tostring(name);
			if stype == "string" then
				info["type"] = "string";
				local nlen = strlen(value);
				if nlen > 128 then
					-- str to long.
					value = ssub(1, 128);
					value = value.."...";
				end
				info["value"] = value;
				info["variablesReference"] = 0;
			elseif stype == "number" then
				info["type"] = "float";
				info["value"] = tostring(value);
				info["variablesReference"] = 0;
			elseif stype == "table" then
				index = index + 1;
				info["value"] = "table";
				info["type"] = "object";
				info["variablesReference"] = index;
				self.var_ref_list[index] = value;
			else
				info["type"] = "string";
				info["value"] = tostring(value);
				info["variablesReference"] = 0;
			end

			count = count + 1;
			body.variables[count] = info;
			if count > 20 then
				-- to much veriables.
				break;
			end
		end
	end

	return body;
end

function ldb_mrg:_get_veriable_by_name(tvariables, tlist)
	local var = nil;
	local nlen = #tlist;
	for i = 1, nlen do 
		local name = tlist[i];
		var = var or tvariables;
		var = var[name];
		if i == nlen then
			return var;
		end
		local stype = type(var);
		if stype ~= "table" and stype ~= "userdata" then
			return nil;
		end
	end
	return var;
end

function ldb_mrg:get_veriable_by_name(expression)
	if l_utily:check_key_word(expression) then
		return "lua key word: "..expression;
	end
	
	local expression = sgsub(expression, ':', '.');
	local tlist = l_utily:split(expression, '.');
	local tupvalues = l_debug:get_upvalue_info();
	local tlocals = l_debug:get_local_info();

	return self:_get_veriable_by_name(tlocals, tlist) or self:_get_veriable_by_name(tupvalues, tlist) or _G[expression];
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
				l_utily:pcall(fhandler, self, sparam);
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
    l_socket:terminated();
end
ldb_mrg:add_io_handler("dettach", ldb_mrg.io_on_dettach);

function ldb_mrg:io_on_detached(t_msg, msg)
	self:restart();
end
ldb_mrg:add_io_handler("detached", ldb_mrg.io_on_detached);

function ldb_mrg:io_on_close(sparam)
	self:stop();
end
ldb_mrg:add_io_handler("close", ldb_mrg.io_on_close);

function ldb_mrg:io_on_do(sparam)
	if l_debug.mode == l_debug.DEBUG_MODE_WAIT then
		self:io_on_default(sparam);
	else
		print("debug> only wait mode can use \"do\"!");
	end
end
ldb_mrg:add_io_handler("do", ldb_mrg.io_on_do);

function ldb_mrg:io_on_default(sline)
	local fun = load(sline);
	if type(fun) == "function" then
		l_utily:pcall(fun);
	end
end

--===================proccess client message========================================
function ldb_mrg:add_msg_handler(command, fhandler)
    self.msg_handler_map = self.msg_handler_map or {};
    self.msg_handler_map[command] = fhandler;
end

function ldb_mrg:proccess_msg()
	local t_list = l_socket:read_msg();
	for _, info in ipairs(t_list) do
		local request = info.t_msg;
		local msg = info.msg;
		if type(request.command) == "string" then
			self.msg_handler_map = self.msg_handler_map or {};
			local fhandler = self.msg_handler_map[request.command];
			if type(fhandler) == "function" then
				local response = l_socket:response_form_request(request);
				l_utily:pcall(fhandler, self, request, request.arguments);
			end
		end
	end
end

function ldb_mrg:msg_on_initialize(request, args)
	local response = l_socket:response_form_request(request);
	self._clientLinesStartAt1 = args.linesStartAt1;
	self._clientColumnsStartAt1 = args.columnsStartAt1;
	response["body"] = response["body"] or {};
	-- the adapter implements the configurationDoneRequest.
	response["body"]["supportsConfigurationDoneRequest"] = false;
	-- make VS Code to use 'evaluate' when hovering over source
	response["body"]["supportsEvaluateForHovers"] = l_utily.supportsHovers;
	-- make VS Code to show a 'step back' button
	response["body"]["supportsStepBack"] = false;
	l_socket:send_msg(response);

	local event = l_socket:create_event("initialized");
	l_socket:send_msg(event);
end
ldb_mrg:add_msg_handler("initialize", ldb_mrg.msg_on_initialize);

function ldb_mrg:msg_on_attach(request, args)
	local response = l_socket:response_form_request(request);
	if args["workingPath"] then
		local workingPath = args["workingPath"];
		workingPath = l_utily:win_style_path(workingPath);
		if ssub(workingPath, -1, -1) ~= '\\' then
			self.workingPath = workingPath..'\\';
		else
			self.workingPath = workingPath;
		end
	end
	l_socket:send_msg(response);
end
ldb_mrg:add_msg_handler("attach", ldb_mrg.msg_on_attach);

function ldb_mrg:msg_on_disconnect(request, args)
	local response = l_socket:response_form_request(request);
	l_socket:send_msg(response);
	if args.restart then
		self:restart();
	else
		l_socket:disconnect();
	end
end
ldb_mrg:add_msg_handler("disconnect", ldb_mrg.msg_on_disconnect);

function ldb_mrg:msg_on_setExceptionBreakpoints(request, args)
	local response = l_socket:response_form_request(request);
	l_socket:send_msg(response);
end
ldb_mrg:add_msg_handler("setExceptionBreakpoints", ldb_mrg.msg_on_setExceptionBreakpoints);

function ldb_mrg:msg_on_configurationDone(request, args)
	local response = l_socket:response_form_request(request);
	l_socket:send_msg(response);
end
ldb_mrg:add_msg_handler("configurationDone", ldb_mrg.msg_on_configurationDone);

function ldb_mrg:msg_on_threads(request, args)
	local response = l_socket:response_form_request(request);
	response.body = 
	{
		threads = 
		{
			{id = 1, name = "thread 1"},
		},
	}
	l_socket:send_msg(response);
end
ldb_mrg:add_msg_handler("threads", ldb_mrg.msg_on_threads);

function ldb_mrg:msg_on_setBreakpoints(request, args)
	local path = l_utily:sub_working_path(args.source.path, self.workingPath);
	local lines = args.lines or {};
	local break_points = self:set_break_points(path, lines);
	local source = args.source;
	local response = l_socket:response_form_request(request);
	local body = {};
	body.breakpoints = {};
	local count = 0;
	for _, line in ipairs(break_points) do 
		count = count + 1;
		local info = {};
		info.line = line;
		info.source = source;
		info.verified = true;
		body.breakpoints[count] = info;
	end
	response.body = body;

	l_socket:send_msg(response);
end
ldb_mrg:add_msg_handler("setBreakpoints", ldb_mrg.msg_on_setBreakpoints);

function ldb_mrg:msg_on_stackTrace(request, args)
	local startFrame = args.startFrame or 0;
	if startFrame == 0 then
		local response = l_socket:response_form_request(request);
		response.body = self:get_stack_trace();
		l_socket:send_msg(response);
	end
end
ldb_mrg:add_msg_handler("stackTrace", ldb_mrg.msg_on_stackTrace);

function ldb_mrg:msg_on_next(request, args)
	l_debug:set_mode(l_debug.DEBUG_MODE_NEXT);
	local response = l_socket:response_form_request(request);
	l_socket:send_msg(response);
end
ldb_mrg:add_msg_handler("next", ldb_mrg.msg_on_next);

function ldb_mrg:msg_on_continue(request, args)
	l_debug:set_mode(l_debug.DEBUG_MODE_RUN);
	local response = l_socket:response_form_request(request);
	l_socket:send_msg(response);
end
ldb_mrg:add_msg_handler("continue", ldb_mrg.msg_on_continue);

function ldb_mrg:msg_on_stepIn(request, args)
	l_debug:set_mode(l_debug.DEBUG_MODE_STEP_IN);
	local response = l_socket:response_form_request(request);
	l_socket:send_msg(response);
end
ldb_mrg:add_msg_handler("stepIn", ldb_mrg.msg_on_stepIn);

function ldb_mrg:msg_on_scopes(request, args)
	local response = l_socket:response_form_request(request);
	local scopes = 
	{
		{name = "normal", variablesReference = 10000, expensive = false},
		{name = "object", variablesReference = 10001, expensive = true},
	};
	response.body = {
		scopes= scopes,
	};
	l_socket:send_msg(response);
end
ldb_mrg:add_msg_handler("scopes", ldb_mrg.msg_on_scopes);

function ldb_mrg:msg_on_variables(request, args)
	local response = l_socket:response_form_request(request);
	local ref_id = args.variablesReference;
	if ref_id then
		if ref_id == 10000 then
			response.body = self:get_normal_veriables();
		elseif ref_id == 10001 then
			self.var_ref_list = {};
			response.body = self:get_object_veriables();
		elseif ref_id > 0 then
			response.body = self:get_single_object(ref_id)
		end
	end
	l_socket:send_msg(response);
end
ldb_mrg:add_msg_handler("variables", ldb_mrg.msg_on_variables);

function ldb_mrg:msg_on_evaluate(request, args)
	local response = l_socket:response_form_request(request);
	-- 'watch': evaluate is run in a watch.
	-- 'repl': evaluate is run from REPL console.
	-- 'hover': evaluate is run from a data hover.
	local context = args["context"]; -- 'hover'
	if context == "hover" and not l_utily.supportsHovers then
		return;
	end
	local expression = args["expression"];
	local value = self:get_veriable_by_name(expression);
	local stype = type(value);
	local info = {};
	if stype == "string" then
		info["type"] = "string";
		local nlen = strlen(value);
		if nlen > 128 then
			-- str to long.
			value = ssub(1, 128);
			value = value.."...";
		end
		info["result"] = value;
		info["variablesReference"] = 0;
	elseif stype == "number" then
		info["type"] = "float";
		info["result"] = tostring(value);
		info["variablesReference"] = 0;
	elseif stype == "table" then
		self.var_ref_list = self.var_ref_list or {};
		local index = #(self.var_ref_list);
		index = index + 1;
		info["result"] = "table";
		info["type"] = "object";
		info["variablesReference"] = index;
		self.var_ref_list[index] = value;
	else
		info["type"] = "string";
		info["result"] = tostring(value);
		info["variablesReference"] = 0;
	end

	response["body"] = info;
	l_socket:send_msg(response);
end
ldb_mrg:add_msg_handler("evaluate", ldb_mrg.msg_on_evaluate);

return ldb_mrg;
