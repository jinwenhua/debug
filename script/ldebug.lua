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
local ssub = string.sub;
local sgsub = string.gsub
local sgmatch = string.gmatch;
local slower = string.lower;
local dsethook = debug.sethook;
local gethook = debug.gethook;
local dgetinfo = debug.getinfo;
local iowrite = io.write
local iolines = io.lines
local tconcat = table.concat;

l_debug = l_debug or {};

l_debug.DEBUG_MODE_RUN = "run";
l_debug.DEBUG_MODE_NEXT = "next";
l_debug.DEBUG_MODE_STEP = "step";
l_debug.DEBUG_MODE_WAIT = "wait";
l_debug.DEBUG_MODE_MATCH = "match";

l_debug.WRITE_ERROR = 0; 
l_debug.WRITE_INFOR = 1; 


function l_debug:init()
    self:_init();
    self.fwrite("l_debug init success.\n");
end

function l_debug.fwrite(...)
    if l_debug._fwrite then
        l_debug._fwrite(...);
		l_debug._fwrite('\n');
    end
end

function l_debug.freadline(...)
    if l_debug._freadline then
        l_debug._freadline(...);
    end
end

function l_debug:_init()
    self._fwrite = iowrite;
    self._freadline = iolines;
    self.map = {};
    self.list = {};
    self.match = {};
    self.count = 0;
    self.enable_count = 0;
    self.mode = self.DEBUG_MODE_RUN;
    self.match.s_file = "";
    self.match.n_begin = 0;
    self.match.n_line = 0;
    self.match.n_end = 0;
    self.match.n_index = 0;
    self.match.b_break = 0;
    self.wokingpath = "";
end

function l_debug:release()
    self:_init();
    self.fwrite("debug finish.\n");
    self:unhook();
end

function l_debug.print(...)
    local t_info = {"debug>", ...};
    local sinfo = tconcat(t_info, "\t").."\n";
    iowrite(sinfo);
end

function l_debug:set_io_fuc(fwrite, freadline)
    self._fwrite = fwrite;
    self._freadline = freadline;
end

function l_debug:set_workingpath(wokingpath)
    wokingpath = wokingpath or "";
    self.wokingpath = sgsub(slower(wokingpath), "/", "\\");
end

function l_debug:get_real_path(file_path)
	local _, _, path = sfind(file_path, "(%w.*)");
	file_path = path or "";
	file_path = sgsub(file_path, '/', '\\');
	file_path = slower(file_path);
	return file_path;
end

-- sbreak : script/test.lua : 17 
function l_debug:add_break_point(sbreak)
    local info, serr = self:get_break_info(sbreak);
    if not info then
        self.fwrite(serr, self.WRITE_ERROR);
        return 0;
    end

    return self:add_break_point_by_info(info.sfile, info.nline, info.enable);
end

function l_debug:add_break_point_by_info(file_name, line_no, benable)
    if type(file_name) ~= "string" then
        return 0;
    end

    benable = benable or 1;

    file_name = self:get_real_path(file_name);
    local t_index = self.map[file_name];
	local info = {};
    if not t_index or not t_index[line_no] then
		t_index = t_index or {};
		info.sfile = file_name;
		info.nline = line_no;
		info.enable = 0;
		self.count = self.count + 1;
		t_index[info.nline] = self.count;
		self.map[info.sfile] = t_index;
		self.list[self.count] = info;
	else
		local index = t_index[line_no]
		info = self.list[index];
    end

    self:_set_enable(info, benable);
    
    local sinfo = sformat("add break point:\n%s:%s\n", info.sfile, info.nline);
    self.fwrite(sinfo, self.WRITE_INFOR);
    return 1;
end

function l_debug:clear_break_point(file_name)
    if type(file_name) ~= "string" then
        return;
    end

    file_name = self:get_real_path(file_name);
    local t_index = self.map[file_name];
    if not t_index then
        return;
    end

    for line_no, index in pairs(t_index) do 
        local info = self.list[index];
        if info then
            self:_set_enable(info, 0);
        end
    end
end

function l_debug:del_break_point(index)
    return self:set_enable(index, 0);
end

function l_debug:show_break_point()
    local t_list = {};
    for i = 1, self.count do 
        local info = self.list[i];
        if info then
            local sinfo = sformat("%s:%s  enable=%s", info.sfile, info.nline, info.enable);
            t_list[#t_list + 1] = sinfo;
        end
    end
    local slist = (t_list[1] and  tconcat(t_list, "\n")) or "no break point.\n";
    self.fwrite(slist.."\n", self.WRITE_INFOR);
end

function l_debug:set_enable(index, benalbe)
    local info = self.list[index];
    if not info then
        local sinfo = "break point don`t exist.\n"
        self.fwrite(sinfo, self.WRITE_INFOR);
        return 0;
    end
    return self:_set_enable(info, benalbe);
end

function l_debug:_set_enable(info, benable)
    benable = benable or 0;
    
	if info.enable ~= benable then
		if benable == 0 then
			if self.match.n_line == info.nline then
				self.match.s_file = "";
				self.match.n_begin = 0;
				self.match.n_line = 0;
				self.match.n_end = 0;
				self.match.n_index = 0;
				self.match.b_break = 0;
			end
			self.enable_count = self.enable_count -1;
			if info.enable ~= benable and self.enable_count <= 0 and gethook() then
				self.enable_count = 0;
				self:unhook();
			end
		else
			self.enable_count = self.enable_count + 1;
			if self.enable_count > 0 and not gethook() then
				self:set_hook_c();
			end
		end
    end

	info.enable = benable;
    local sinfo = "break point set: enable = "..benable..'\n';
    self.fwrite(sinfo, self.WRITE_INFOR);  
    return 1;
end

function l_debug:set_mode(smode)
    self.mode = smode or self.DEBUG_MODE_NEXT;
    local sinfo = sformat("debug mode change to: %s", self.mode);
    self.fwrite(sinfo..'\n', self.WRITE_INFOR);
    return 1;
end

function l_debug:find_index(ssource, nlinedefined, nlastlinedefined)
    if type(ssource) ~= "string" then
        return nil;
    end

    ssource = self:get_real_path(ssource);
    local t_index = self.map[ssource];
	if type(t_index) ~= "table" then
		return nil;
    end

    for line_no, index in pairs(t_index) do 
        if line_no >= nlinedefined and line_no <= nlastlinedefined then
            return index;
        end
    end

    return nil;
end

function l_debug.hook_c(cmd)
    local self = l_debug;
	local info = dgetinfo(2, "S");
	local s_source = info["source"];
	local s_what = info["what"];
	local n_linedefined = info["linedefined"];
    local n_lastlinedefined = info["lastlinedefined"];
    
    if s_what ~= "Lua" then
        return;
    end

    -- local sinfo = sformat("[%s|%s]%s:%s\n", s_what, cmd, s_source, n_linedefined);
    -- self.fwrite(sinfo, self.WRITE_INFOR);
    local index = self:find_index(s_source, n_linedefined, n_lastlinedefined);
	if type(index) ~= "number" then
		return;
    end
    
    local info = self.list[index];
    if not info then
        return;
    end

	if info.enable == 1 then
		self.match.s_file = info.path;
		self.match.n_begin = n_linedefined;
		self.match.n_line = info.nline;
        self.match.n_end = n_lastlinedefined;
        self.match.n_index = index;
        self.match.b_break = 0;
        self:set_mode(self.DEBUG_MODE_NEXT);
		self:set_hook_crl();
	end
end

function l_debug:set_hook_c()
    dsethook(self.hook_c, "c");
end

function l_debug.hook_crl(cmd, line)
    local self = l_debug;
    if self.mode == self.DEBUG_MODE_RUN then
        ldb_mrg:set_msg_cach("next", nil);
        self:set_hook_c();
        return;
    elseif cmd == "call" and self.mode == self.DEBUG_MODE_NEXT then
        self:set_hook_r();
        return;
	elseif cmd == "call" and self.mode == self.DEBUG_MODE_STEP then
        self:set_mode(self.DEBUG_MODE_NEXT);
		return;
	end

	local info = dgetinfo(2, "Sln");
	local s_source = info["source"];
	local s_what = info["what"] or "";
	local s_currentline = info["currentline"];
	local s_name = info["name"];
	local n_linedefined = info["linedefined"];
    local n_lastlinedefined = info["lastlinedefined"];
    if s_what ~= "Lua" and s_what ~= "main" then
        return;
    end

    s_source = self:get_real_path(s_source);
    if self.match.b_break == 0 then
        if s_currentline == self.match.n_line and 
            n_linedefined == self.match.n_begin and 
                n_lastlinedefined == self.match.n_end then
            -- match break
			self.match.b_break = 1;
            ldb_mrg:send_match_break_point(s_source, s_currentline);
		else
			return;
        end
    end
    self:set_mode(self.DEBUG_MODE_NEXT);
    
	if s_what == "Lua" and cmd == "line" then
		ldb_mrg:updatestackinfo(2)
		
		local tparam = {};
		tparam.path = s_source;
		tparam.line = s_currentline;
		ldb_mrg:send_next_cach(tparam);
		
		self.mode = self.DEBUG_MODE_WAIT;
		while self.mode == self.DEBUG_MODE_WAIT do 
			ldb_mrg:on_tick(self.DEBUG_MODE_WAIT);
			ldb_mrg:sleep(100);
		end
	end



    if cmd == "line" and line ~= n_lastlinedefined and s_source == self.match.s_file then
        local sinfo = sformat("[%s|%s]%s:%s in %s()\n", s_what, cmd, s_source or "nil", s_currentline or "nil", s_name or "nil");
        self.fwrite(sinfo, self.WRITE_INFOR);
    end

    if cmd == "return" and s_source == self.match.s_file and 
            self.match.n_line >= n_linedefined and
                self.match.n_line <= n_lastlinedefined then
        self.match.s_file = "";
        self.match.n_begin = 0;
        self.match.n_line = 0;
        self.match.n_end = 0;
        self.match.n_index = 0;
        self.match.b_break = 0;
        self:set_hook_c();
    end

end

function l_debug:set_hook_crl()
    dsethook(self.hook_crl, "crl");
end

function l_debug.hook_cr(cmd)
    local self = l_debug;
    self:set_mode(self.DEBUG_MODE_NEXT);
	local info = dgetinfo(2, "S");
	-- local info = dgetinfo(2, "Sl");
	local s_source = info["source"];
	-- local s_what = info["what"];
	-- local n_currentline = info["currentline"];
	-- if s_what ~= "Lua" then
		-- return;
    -- end
    
    -- local sinfo = sformat("[%s|%s]%s:%s\n", s_what, cmd, s_source, n_currentline);
    -- self.fwrite(sinfo, self.WRITE_INFOR);
	self.n_current_return = self.n_current_return or 1;
	if cmd == "call" then
		self.n_current_return = self.n_current_return + 1;
	elseif cmd == "return" then
		self.n_current_return = self.n_current_return - 1;
	end
	if self.n_current_return <= 0 then
		self.n_current_return = 1;
		self:set_hook_crl();
		return;
	end
end

function l_debug:set_hook_r()
    dsethook(self.hook_cr, "cr");
end

function l_debug:unhook()
    debug.sethook();
end

-- l_debug:get_break_info("E:\\github\\Lengineset\\project\\test\\lua\\script\\test.lua : 17     ")
function l_debug:get_break_info(sbreak)
    local _, _, file_name, l = sfind(sbreak, "(%w+.*%.%w+)%s*:%s*(%d+)%s*");
    if not file_name then
        return nil, "invalid in put.\n";
    end
    local line = tonumber(l);
    if not line then
        return nil, "line num error.\n";
    end
    local info = {}
    file_name = self:get_real_path(file_name);
    info.sfile = file_name;
    info.nline = line;
    info.enable = 1;
    return info;
end

-- l_debug:init();
-- l_debug:release();

return l_debug;
