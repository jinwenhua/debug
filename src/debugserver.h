#ifndef __DEBUG_SERVER_H__
#define __DEBUG_SERVER_H__

#include <stdio.h>
#include <stdlib.h>  
#include <stddef.h>  
#include <errno.h>
#include <thread>         // std::thread
#include <mutex>          // std::mutex, std::lock_guard, std::adopt_lock
#include <chrono>
#include <functional>
#include <atomic>
#include <winsock2.h> 
#include <windows.h>
#include <synchapi.h>
#include <string>
#include <queue>
#include "luawrapper.h"

#include <iostream>
#include <fstream>  
#include <stdexcept>      // std::logic_error

#pragma comment(lib, "WS2_32")

#define _TCP_MAX_CONN_WAIT          10
#define _TCP_CHAR_IP_LEN            33
#define _TCP_MAX_BUFFER_SIZE        (1024 * 4)

struct lua_State;
class DebugServerWrapper;

enum class DBG_RUN_STATE {DBG_NONE, DBG_DETACH, DBG_ATTACH};

struct RegType
{
    const char *name;
    int (DebugServerWrapper::*mfunc)(lua_State *L);
};

class DebugServer 
{
public:
    DebugServer();
    ~DebugServer();

public:
    int StartServer(short port);
    int StoprServer();
    int Send(std::string& msg);
	int Recv(std::string& msg);
    int Dettach();
    void SetRunState(DBG_RUN_STATE st);
    bool CheckRunState(DBG_RUN_STATE st);
	int ReadCmd(std::string& cmd);
	void StartConsole();
	void StopConsole();
private:
	int _Recv(std::string& msg);
    int InitServer();
    void AcceptThread();
    int UnInit();
	void StopThread();
	void StartRecv();
	void StopRecv();
private:
    DBG_RUN_STATE m_dbgstate;
    int m_nSocketLisent = INVALID_SOCKET;
    int m_nSocketClient = INVALID_SOCKET;
    short m_nPort = -1;
	int m_nPing = 30;
    std::mutex m_mtx;
    std::thread m_Thread;

	std::mutex m_mtxconsole;
	std::thread m_ThreadConsole;
	std::queue<std::string> m_qConsole;

	std::mutex m_mtxRecv;
	std::thread m_ThreadRecv;
	std::queue<std::string> m_qRecv;
};


class DebugServerWrapper: L_INHERIT_CALSS(DebugServer)
{
public:
	typedef DebugServer superclass;
    DebugServerWrapper(lua_State* L);
    ~DebugServerWrapper();

public:
    int StartServer(lua_State* L);
    int StoprServer(lua_State* L);
    int Send(lua_State* L);
    int Recv(lua_State* L);
	int Dettach(lua_State* L);
	int ReadCmd(lua_State* L);
	int StartConsole(lua_State* L);
	int StopConsole(lua_State* L);
	int sleepmilliseconds(lua_State* L);
	// 需要放最后，这个宏定义public成员，若放中间会改变其他成员的访问权限
	L_DECLARE_LUA_CLASS(DebugServerWrapper);
};

class MyTest
{
public:
	MyTest() {}
	~MyTest() {}

public:
	int Foo(int a)
	{
		printf("_Foo_(%d)\n", a);
		id = a;
		return 1;
	}
private:
	int id = 0;
};

class MyTestWrapper : L_INHERIT_CALSS(MyTest)
{
public:
	MyTestWrapper(lua_State* L):L_INHERIT_TYPE(MyTest)(L)
	{
		
	}
	~MyTestWrapper() {}

public:
	int LuaFoo(lua_State* L);

	// 需要放最后，这个宏定义public成员，若放中间会改变其他成员的访问权限
	L_DECLARE_LUA_CLASS(MyTestWrapper);
};

#endif //__DEBUG_SERVER_H__
