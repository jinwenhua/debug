-- test 
for path, info in pairs(l_debug.map) do 
	for line, enable in pairs(info) do 
		print(111, path, line, enable);
	end
end