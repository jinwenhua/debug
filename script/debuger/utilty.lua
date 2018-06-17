local sformat = string.format;
local sfind = string.find;
local strlen = string.len;
local ssub = string.sub;
local sgsub = string.gsub;
local sgmatch = string.gmatch;
local smatch = string.match;
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

ldb_json = ldb_json or require("json");
l_utily = l_utily or {};

l_utily.luaX_tokens = {
    ["and"] = 1, ["break"] = 1, ["do"] = 1, ["else"] = 1 , ["elseif"] = 1,
    ["end"] = 1, ["false"] = 1, ["for"] = 1, ["function"] = 1, ["goto"] = 1, ["if"] = 1,
    ["in"] = 1, ["local"] = 1, ["nil"] = 1, ["not"] = 1, ["or"] = 1, ["repeat"] = 1,
    ["return"] = 1, ["then"] = 1, ["true"] = 1, ["until"] = 1, ["while"] = 1,
    ["//"] = 1, [".."] = 1, ["..."] = 1, ["=="] = 1, [">="] = 1, ["<="] = 1, ["~="] = 1,
    ["<<"] = 1, [">>"] = 1, ["::"] = 1, ["<eof>"] = 1,
    ["<number>"] = 1, ["<integer>"] = 1, ["<name>"] = 1, ["<string>"] = 1
};

function l_utily:split(src, delim)
	src = src or '';
	delim = delim or '%s';
	local tlist = {};
	local count = 0;
	for line in sgmatch(src, "([^"..delim.."]+)") do
		-- print(111, line);
		count = count + 1;
		tlist[count] = line;
	end
	return tlist;
end

function l_utily:split_raw_msg(raw_msg)
    local tmsg_list = {};
    local stail = raw_msg or '';
    local count = 0;
    while true do
        local strlen, snext = smatch(stail, "Content%-Length: (%d+)%c+(.*)");
        if strlen and snext then
            local nlen = tonumber(strlen);
            local msg = ssub(snext, 1, nlen);
            count = count + 1;
            tmsg_list[count] = msg;
            stail = ssub(snext, nlen);
        else
            break;
        end
    end
    return tmsg_list;
end

function l_utily:win_style_path(file_path)
	local _, _, path = sfind(file_path, "(%w.*)");
	file_path = path or "";
	file_path = sgsub(file_path, '/', '\\');
	file_path = slower(file_path);
	return file_path;
end

function l_utily:sub_working_path(path, workingPath)
	path = self:win_style_path(path);
	local nlen = strlen(workingPath);
	path = ssub(path, nlen + 1);
	return path;
end

function l_utily:encode(t_msg)
	local ok, msg = self:pcall(ldb_json.encode, t_msg);
	if ok and type(msg) == "string" then
		return msg;
	end

	return nil;
end

function l_utily:decode(msg)
	local ok, t_msg = self:pcall(ldb_json.decode, msg);
	if ok and type(t_msg) == "table" then
		return t_msg;
	end

	return nil;
end

function l_utily:pcall(func, ...)
    local errhander = function(e)
        print("debug> error info: "  .. e);
        print("debug> stack info: " .. dtraceback("current 2 stack: " ,2));
    end

    return fxpcall(func, errhander, ...);
end

function l_utily:check_key_word(expression)
	if self.luaX_tokens[expression] then
		return true;
	end
	return false;
end



return l_utily;

