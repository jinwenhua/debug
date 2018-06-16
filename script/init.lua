--[[
@ lua debug for vs code
@
@ Author luhengsi 
@ Mail   luhengsi@163.com
@ Date   2018-06-10
@
@ please check Licence.txt file for licence and legal issues. 
]]
l_utily = l_utily or {};

-- make VS Code to use 'evaluate' when hovering over source
l_utily.supportsHovers = true;

local dgetinfo = debug.getinfo;
local sfind = string.find;
local ssub = string.sub;
local slower = string.lower;
local sformat = string.format;
function l_utily:get_working_path(nlevel)
    nlevel = nlevel or 0;
    nlevel = nlevel + 1;
	local info = dgetinfo(nlevel, "S");
	local path = info.source or '';
	path = ssub(path, 2, -1) -- delete "@"  
    local _, _, path = sfind(path, "^(.*)\\") -- the last "/" befor 
    path = slower(path or "");
	return path;
end

function l_utily:init()
	if not self._if_init_ then
		self._if_init_ = 1;
		local workingpath = l_utily:get_working_path(0);
		print("debug> current cwd:", workingpath)
		package.path = package.path or "";
		package.path = sformat(".\\%s\\?.lua;%s", workingpath, package.path);
		package.cpath = package.cpath or "";
		package.cpath = sformat(".\\%s\\?.dll;%s", workingpath, package.cpath);
		ldb_json = ldb_json or require("json");
		json = nil;
		require("utilty");
		l_socket = l_socket or require("protocol");
		l_debug = l_debug or require("ldebug");
		ldb_mrg = ldb_mrg or require("ldbmrg");
	
		local port = 8869;
		ldb_mrg:init(port, 0);
		ldb_mrg:run()
	end
end

l_utily:init()

-- dofile("init.lua")
