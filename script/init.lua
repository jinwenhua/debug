--[[
@ lua debug for vs code
@
@ Author luhengsi 
@ Mail   luhengsi@163.com
@ Date   2018-06-10
@
@ please check Licence.txt file for licence and legal issues. 
]]

-- dofile("init.lua")
local sformat = string.format;
local ssub = string.sub;
local sfind = string.find;
local dgetinfo = debug.getinfo;

local f_get_working_path = function()
	local info = dgetinfo(1, "S");
	local path = info.source;
	path = ssub(path, 2, -1) -- delete "@"  
	local _, _, path = sfind(path, "^(.*)\\") -- the last "/" befor 
	return path;
end

if not l_debug then
	local workingpath = f_get_working_path();
	package.path = package.path or "";
	package.path = sformat(".\\%s\\?.lua;%s", workingpath, package.path);
	package.cpath = package.cpath or "";
	package.cpath = sformat(".\\%s\\?.dll;%s", workingpath, package.cpath);

	l_debug = l_debug or require("ldebug");
	ldb_mrg = ldb_mrg or require("ldbmrg");

	local port = 8869;

	l_debug:init();
	l_debug:set_workingpath(workingpath);
	ldb_mrg:init(port, 0);
	ldb_mrg:run()
end
