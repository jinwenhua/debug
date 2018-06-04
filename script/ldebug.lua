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

l_debug.DEBUG_MODE_NEXT = "next";
l_debug.DEBUG_MODE_STEP = "step";

l_debug.WRITE_ERROR = 0; 
l_debug.WRITE_INFOR = 1; 


function l_debug:init()
    self:_init();
    self.fwrite("init success.");
end

function l_debug:_init()
    self.fwrite = self.print;
    self.freadline = iolines;
    self.map = {};
    self.list = {};
    self.match = {};
    self.count = 0;
    self.enable_count = 0;
    self.mode = self.DEBUG_MODE_NEXT;
    self.match.s_file = "";
    self.match.n_begin = 0;
    self.match.n_line = 0;
    self.match.n_end = 0;
    self.match.n_index = 0;
    self.spre = "";
end

function l_debug:release()
    self:_init();
    self.fwrite("debug finish.");
    self:unhook();
end

function l_debug.print(...)
    local t_info = {"debug>", ...};
    local sinfo = tconcat(t_info, "\t").."\n";
    iowrite(sinfo);
end

function l_debug:set_io_fuc(fwrite, freadline)
    self.fwrite = fwrite;
    self.freadline = freadline;
end

function l_debug:set_prefix(spre)
    spre = spre or "";
    self.spre = sgsub(slower(spre), "\\", "/");
end
-- sbreak : script/test.lua : 17 
function l_debug:add_break_point(sbreak)
    local info, serr = self:get_break_info(sbreak);
    if not info then
        self.fwrite(serr, self.WRITE_ERROR);
        return 0;
    end

    local t_index = self.map[info.sfile];
    if t_index and t_index[info.nline] then
        local serr = sformat("this postion haved a break point: \n%s:%s", info.sfile, info.nline);
        self.fwrite(serr, self.WRITE_ERROR);
        return 0;
    end

    t_index = t_index or {};
    self.count = self.count + 1;
    t_index[info.nline] = self.count;
    self.map[info.sfile] = t_index;
    self.list[self.count] = info;
    self.enable_count = self.enable_count + 1;
    
    if self.enable_count > 0 and not gethook() then
        self:set_hook_c();
    end
    
    local sinfo = sformat("add break point:\n%s:%s", info.sfile, info.nline);
    self.fwrite(sinfo, self.WRITE_INFOR);
    return 1;
end

function l_debug:del_break_point(index)
    local info = self.list[index];
    if not info then
        local sinfo = "break point don`t exist."
        self.fwrite(sinfo, self.WRITE_INFOR);
        return 0;
    end

    if info.enable == 1 then
        info.enable = 0;
        self.enable_count = self.enable_count - 1;
    end

    if self.match.n_line == info.nline then
        self.match.s_file = "";
        self.match.n_begin = 0;
        self.match.n_line = 0;
        self.match.n_end = 0;
        self.match.n_index = 0;
    end
    
    if self.enable_count <= 0 and gethook() then
        self.enable_count = 0;
        self:unhook();
    end
    
    local sinfo = "break point deleted success."
    self.fwrite(sinfo, self.WRITE_INFOR);  
    return 1;
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
    local slist = (t_list[1] and  tconcat(t_list, "\n")) or "no break point.";
    self.fwrite(slist, self.WRITE_INFOR);
end

function l_debug:set_enable(index, benalbe)
    local info = self.list[index];
    if not info then
        local sinfo = "break point don`t exist."
        self.fwrite(sinfo, self.WRITE_INFOR);
        return 0;
    end

    benalbe = benalbe or 0;

    info.enable = benalbe;
    if self.match.n_line == info.nline then
        self.match.s_file = "";
        self.match.n_begin = 0;
        self.match.n_line = 0;
        self.match.n_end = 0;
        self.match.n_index = 0;        
    end

    if benalbe == 0 then
        self.enable_count = self.enable_count -1;
        if self.enable_count <= 0 and gethook() then
            self.enable_count = 0;
            self:unhook();
        end
    else
        self.enable_count = self.enable_count + 1;
        if self.enable_count > 0 and not gethook() then
            self:set_hook_c();
        end
    end

    local sinfo = "break point set: enable = "..benalbe;
    self.fwrite(sinfo, self.WRITE_INFOR);  
    return 1;
end

function l_debug:set_mode(smode)
    self.mode = smode or self.DEBUG_MODE_NEXT;
    local sinfo = sformat("debug mode change to: %s", self.mode);
    self.fwrite(sinfo, self.WRITE_INFOR);
    return 1;
end

function l_debug:find_index(ssource, nlinedefined, nlastlinedefined)
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

    s_source = slower(s_source);
    s_source = sgsub(s_source, "\\", "/");
    -- local sinfo = sformat("[%s|%s]%s:%s", s_what, cmd, s_source, n_linedefined);
    -- self.fwrite(sinfo, self.WRITE_INFOR);
    local index = self:find_index(s_source, n_linedefined, n_lastlinedefined);
	if type(index) ~= "number" then
		return;
    end
    
    local info = self.list[index];
    if not info then
        return;
    end

	if info.enable ~= 0 then
		self.match.s_file = s_source;
		self.match.n_begin = n_linedefined;
		self.match.n_line = info.nline;
        self.match.n_end = n_lastlinedefined;
        self.match.n_index = index;
		self:set_hook_crl();
	end
end

function l_debug:set_hook_c()
    dsethook(self.hook_c, "c");
end

function l_debug.hook_crl(cmd, line)
    local self = l_debug;
	if cmd == "call" and self.mode == self.DEBUG_MODE_NEXT then
		self:set_hook_r();
	elseif cmd == "call" and self.mode == self.DEBUG_MODE_STEP then
		self.mode = "next";
		return;
	end
    self.mode = "next";
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

    s_source = slower(s_source);
    s_source = sgsub(s_source, "\\", "/");
    if cmd == "line" and line ~= n_lastlinedefined and s_source == self.match.s_file then
        local sinfo = sformat("[%s|%s]%s:%s in %s()", s_what, cmd, s_source or "nil", s_currentline or "nil", s_name or "nil");
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
        self:set_hook_c();
    end

end

function l_debug:set_hook_crl()
    dsethook(self.hook_crl, "crl");
end

function l_debug.hook_r(cmd)
    local self = l_debug;
	local info = dgetinfo(2, "Sl");
	local s_source = info["source"];
	local s_what = info["what"];
	local n_currentline = info["currentline"];
	if s_what ~= "Lua" then
		return;
    end
    
    -- local sinfo = sformat("[%s|%s]%s:%s", s_what, cmd, s_source, n_currentline);
    -- self.fwrite(sinfo, self.WRITE_INFOR);
	self:set_hook_crl()
end

function l_debug:set_hook_r()
    dsethook(self.hook_r, "r");
end

function l_debug:unhook()
    debug.sethook();
end

-- l_debug:get_break_info("E:\\github\\Lengineset\\project\\test\\lua\\script\\test.lua : 17     ")
function l_debug:get_break_info(sbreak)
    local _, _, file, l = sfind(sbreak, "(%w+.*%.%w+)%s*:%s*(%d+)%s*");
    if not file then
        return nil, "invalid in put.";
    end
    local line = tonumber(l);
    if not line then
        return nil, "line num error.";
    end
    local info = {}
    file = sgsub(file, "\\", "/");
    file = slower(file);
    file = sformat("@%s/%s", self.spre, file);
    file = sgsub(file, "///", "/");
    file = sgsub(file, "//", "/");
    info.sfile = file;
    info.nline = line;
    info.enable = 1;
    return info;
end

l_debug:init();
-- l_debug:release();

return l_debug;
