#ifndef __DEBUG_DLL_H__
#define __DEBUG_DLL_H__

#if defined(LDEBUG_BUILD_AS_DLL)	/* { */

#if defined(LDEBUG_CORE) || defined(LDEUBG_LIB)	/* { */
#define LDEBUG_API __declspec(dllexport)
#else						/* }{ */
#define LDEBUG_API __declspec(dllimport)
#endif						/* } */

#else				/* }{ */

#define LDEBUG_API 	__declspec(dllimport)

#endif				/* } */

extern "C" {
	#include "luaconf.h"
	#include "lua.h"
	#include "lualib.h"
	#include "lauxlib.h"
	LDEBUG_API int luaopen_ldebugserver(lua_State* L);
}




#endif //__DEBUG_DLL_H__