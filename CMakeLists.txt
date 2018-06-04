project(main)
cmake_minimum_required(VERSION 3.0)
#cmake -DCMAKE_BUILD_TYPE=Debug

IF (WIN32)  
    MESSAGE(STATUS "Now is windows")  
ELSEIF (APPLE)  
    MESSAGE(STATUS "Now is Apple systens.")  
ELSEIF (UNIX)  
    MESSAGE(STATUS "Now is UNIX-like OS's. Including aPPLE os x  and CygWin")  
ENDIF () 

# add_definitions(-DLUA_BUILD_AS_DLL)

include_directories(
    ./include
    ./include/lua
    ./src
)

find_library(lua_lib lua ./lib NO_DEFAULT_PATH)


link_libraries(
    ${lua_lib} 
    )

set(
    SRC_LIST ./test/main.cpp
    ./src/debugserver.cpp
)
add_executable(main ${SRC_LIST})

## BUILD
# Create lua library
set( 
    LIBLDB_SRC ./src/debugserver.cpp
    ./src/debug_dll.cpp
    ) 
add_library ( ldebugserver SHARED  ${LIBLDB_SRC})
set_target_properties ( ldebugserver PROPERTIES COMPILE_DEFINITIONS LDEBUG_BUILD_AS_DLL )
set_target_properties ( ldebugserver PROPERTIES COMPILE_DEFINITIONS LDEUBG_LIB )
set_target_properties ( ldebugserver PROPERTIES COMPILE_DEFINITIONS LUA_USE_WINDOWS )
target_link_libraries ( ldebugserver ${lua_lib} )

