-- dofile("init.lua")
l_debug = l_debug or require("ldebug");
ldb_mrg = ldb_mrg or require("ldbmrg");

local port = 8869;
-- local workingpath = "";

l_debug:init();
-- l_debug:set_prefix(workingpath);
ldb_mrg:init(port, 0);
