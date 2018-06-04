
#include "../src/debugserver.h"
#include <stdlib.h>
#include <stdio.h>
#include <direct.h>  
#include "luawrapper.h"
#include "../src/debug_dll.h"

int main(int argc, char *argv[])
{
    lua_State* luaEnv = luaL_newstate();
    if (!luaEnv)
    {
        printf("lua_open fail!\n");
        return 0;
    }

    luaL_openlibs(luaEnv);
	L_LUA_WRAPPER_REGISTER(DebugServerWrapper, luaEnv);
	char *buffer;
	char path[256] = { 0 };
	//也可以将buffer作为输出参数  
	if ((buffer = getcwd(NULL, 0)) == NULL)
	{
		perror("getcwd error");
	}
	else
	{
		sprintf(path, "%s\\test.lua", buffer);
        path[254] = 0;
		printf("file: %s\n", buffer);
		free(buffer);
	}

    int nRetCode = luaL_dofile(luaEnv, path);
    if(nRetCode)
    {
        printf("error pcall:\n %s\n", luaL_tolstring(luaEnv, -1, NULL));
    }

    lua_getglobal(luaEnv, "on_tick");
    lua_pcall(luaEnv, 0, 0, 0);
    lua_pop(luaEnv, -1);
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    lua_close(luaEnv);

    getchar();
    return 0;
}





