
#ifndef LDEBUG_BUILD_AS_DLL
#define LDEBUG_BUILD_AS_DLL

#ifndef LDEUBG_LIB
#define LDEUBG_LIB
#endif // !LDEUBG_LIB


#endif // !LDEBUG_BUILD_AS_DLL


#include "debug_dll.h"
#include "debugserver.h"

LDEBUG_API int luaopen_ldebugserver(lua_State* L)
{
	printf("load debug server module success.\n");
    L_LUA_WRAPPER_REGISTER(DebugServerWrapper, L);
	return 0;
}