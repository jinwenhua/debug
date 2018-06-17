project ( lua C )
cmake_minimum_required(VERSION 3.0)

set (LUAOBJS 
	lstate.c 
	lapi.c 
	lmem.c 
	lstring.c 
	ltable.c 
	ltm.c 
	lvm.c 
	ldo.c 
	lobject.c 
	lfunc.c 
	lgc.c 
	lcode.c 
	lparser.c 
	llex.c 
	lundump.c 
	lzio.c 
	ldebug.c 
    ltests.c
	lauxlib.c 
	lbaselib.c 
	liolib.c 
	lmathlib.c 
	lstrlib.c 
	ldblib.c
)

set(SRC_LUA
    lua.c
)

add_library( liblua SHARED ${LUAOBJS} )
set_target_properties ( liblua PROPERTIES OUTPUT_NAME lua)
add_library( liblua_static STATIC ${LUAOBJS} )
set_target_properties ( liblua_static PROPERTIES OUTPUT_NAME lua)
add_executable ( lua ${SRC_LUA} )
target_link_libraries ( lua liblua )
