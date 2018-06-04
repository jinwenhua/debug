project(ldb)
cmake_minimum_required(VERSION 3.0)
#cmake -DCMAKE_BUILD_TYPE=Debug

IF (WIN32)  
    MESSAGE(STATUS "Now is windows")  
ELSEIF (APPLE)  
    MESSAGE(STATUS "Now is Apple systens.")  
ELSEIF (UNIX)  
    MESSAGE(STATUS "Now is UNIX-like OS's. Including aPPLE os x  and CygWin")  
ENDIF () 


include_directories(
    ./include
    ./include/lua
    ./src
    )

link_directories("lib")
    
find_library(lua_lib lua ./lib NO_DEFAULT_PATH)
    
set(
    SRC_LIST ./test/main.cpp
    ./src/debugserver.cpp
    )
        
## test
add_executable(test ${SRC_LIST})
# target_compile_definitions(test PRIVATE "LUA_BUILD_AS_DLL")
target_link_libraries ( test lua.lib )

set( 
    LIBLDB_SRC ./src/debugserver.cpp
    ./src/debug_dll.cpp
    ) 

## dll 
add_library ( ldebugserver SHARED  ${LIBLDB_SRC})

target_compile_definitions(ldebugserver 
                            PRIVATE "LUA_USE_WINDOWS"
                            PRIVATE "LDEBUG_BUILD_AS_DLL"
                            PRIVATE "LDEUBG_LIB"
                            )
target_link_libraries ( ldebugserver lua.lib )

