project(ldb)
cmake_minimum_required(VERSION 2.8)
#cmake -DCMAKE_BUILD_TYPE=Debug

IF (WIN32)  
    MESSAGE(STATUS "Now is windows") 
    include_directories(
    ./include
    ./include/lua/win
    ./src
    )
ELSEIF (APPLE)  
    MESSAGE(STATUS "Now is Apple systens.")  
    include_directories(
    ./include
    ./include/lua/linux
    ./src
    )
ELSEIF (UNIX)  
    MESSAGE(STATUS "Now is UNIX-like OS's. Including aPPLE os x  and CygWin")  
    include_directories(
    ./include
    ./include/lua/linux
    ./src
    )
ENDIF () 


#link_directories("lib")
    
find_library(lua_lib lua ./lib NO_DEFAULT_PATH)
    
set(
    SRC_LIST ./test/main.cpp
    ./src/debugserver.cpp
    )
        
## test
add_executable(test ${SRC_LIST})
# target_compile_definitions(test PRIVATE "LUA_BUILD_AS_DLL")

set( 
    LIBLDB_SRC ./src/debugserver.cpp
    ./src/debug_dll.cpp
    ) 

## dll 
add_library ( ldebugserver SHARED  ${LIBLDB_SRC})
IF (WIN32)  
target_link_libraries ( test ${lua_lib} )
target_compile_definitions(test 
                            PRIVATE "LUA_BUILD_AS_DLL"
                            )
target_compile_definitions(ldebugserver 
                            PRIVATE "LUA_BUILD_AS_DLL"
                            PRIVATE "LDEBUG_BUILD_AS_DLL"
                            PRIVATE "LDEUBG_LIB"
                            )
target_link_libraries ( ldebugserver ${lua_lib} )
ELSEIF (APPLE)  
target_link_libraries ( test ${lua_lib} dl pthread )
target_compile_definitions(test 
							PRIVATE "LUA_USE_MACOSX"
                            PRIVATE "LDEBUG_BUILD_AS_DLL"
                            )
target_link_libraries ( ldebugserver pthread )
target_compile_definitions(ldebugserver 
							PRIVATE "LUA_USE_MACOSX"
                            PRIVATE "LDEBUG_BUILD_AS_DLL"
                            )
ELSEIF (UNIX)  
target_link_libraries ( test ${lua_lib} dl  pthread )
target_compile_definitions(test 
							PRIVATE "LUA_USE_LINUX"
                            PRIVATE "LDEBUG_BUILD_AS_DLL"
                            )
target_link_libraries ( ldebugserver pthread )
target_compile_definitions(ldebugserver 
							PRIVATE "LUA_USE_LINUX"
                            PRIVATE "LDEBUG_BUILD_AS_DLL"
                            )
ENDIF () 


#target_link_libraries ( ldebugserver ${lua_lib} )
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ./script)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ./script)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ./script)
if (CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    target_compile_options(test PRIVATE "-std=c++11")
    target_compile_options(ldebugserver PRIVATE "-std=c++11")
    MESSAGE(STATUS "change complie to c++11")  
endif()

