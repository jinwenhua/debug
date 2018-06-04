// 
// @filename:    luawrpper.h
// @Author:      luhengsi
// @DateTime:    2018-05-31 11:50:23
// @Description: define lua wrapper
// @Description: 

/*
一个 c++ 类导出到 lua 的简单的基本模型
使用方法：
	1. 声明和定义被导出了c++类: MyTest，这个类可以是不含lua操作的类。
	   也可以有lua操作，看需求定。
	2. 声明和定义保包装类: MyTestWarpper。声明和定义需要用到下面一系列的宏定义，
	   用来绑定 MyTestWarpper 和 MyTest的关系。
	3. 使用 L_LUA_WRAPPER_REGISTER(MyTestWarpper, luaEvn);来调用注册要导出的类，
	   以及类的方法。

文件结构：
--=========================================================================
-----------test.h------------
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

--=========================================================================
-------------test.cpp--------------

L_DEFINE_LUA_CLASS(MyTestWrapper, MyTest);

int MyTestWrapper::LuaFoo(lua_State* L)
{
	int port = luaL_checkinteger(L, 1);
	Foo(port);
	return 1;
}

L_REG_TYPE(MyTestWrapper) MyTestWrapper::Functions[] =
{
	{ "Foo", &MyTestWrapper::LuaFoo },
	{NULL, NULL}
};
--========================================================================
-------------main.cpp----------------
int main(int argc, char *argv[])
{
	lua_State* luaEnv = luaL_newstate();
	if (!luaEnv)
	{
		printf("lua_open fail!\n");
		return 0;
	}

	luaL_openlibs(luaEnv);
	L_LUA_WRAPPER_REGISTER(MyTestWrapper, luaEnv);
	int nRetCode = luaL_dofile(luaEnv, "test.lua");
	if(nRetCode)
	{
		printf("error pcall:\n %s\n", luaL_tolstring(luaEnv, -1, NULL));
	}
	lua_close(luaEnv);
	getchar();
	return 0;
}
--========================================================================
---------------test.lua--------------------------------
local mytest = MyTest()
mytest:Foo(99);
--========================================================================

*/

#ifndef __LUA_WRAPPER_H__
#define __LUA_WRAPPER_H__

extern "C" {
    #include "lua.h"
    #include "lualib.h"
    #include "lauxlib.h"
}

#ifndef __stringify_1
// 将token转化成字符串
#define  __stringify_1(x)   #x
#endif

// 
#define L_REG_TYPE(T) luacpp::_RegType<T>

// 
#define L_INHERIT_TYPE(N) luacpp::LunaBase<N>

// 继承要包装类的宏
#define L_INHERIT_CALSS(N)  public L_INHERIT_TYPE(N)

// lua包装类声明
#define L_DECLARE_LUA_CLASS(T) \
public: \
	static const char* className; \
	static L_REG_TYPE(T) Functions[]; \
private: \
	const char* _Version() { return #T" lua wrapper 0.1"; }


// lua包装类定义导出的类名
// T包装类， N 导出的 c++ 类
#define L_DEFINE_LUA_CLASS(T, N) \
const char* T::className = __stringify_1(N)


// 注册
#define L_LUA_WRAPPER_REGISTER(T, L) luacpp::Luna<T>::Register(L) 

namespace luacpp
{

template <typename T>
struct _RegType
{
	const char *name;
	int (T::*mfunc)(lua_State *L);
};

template <typename N>
class LunaBase : public N
{
public:
	LunaBase(lua_State* L) :m_Lua(L)
	{

	}

	~LunaBase()
	{
		m_Lua = nullptr;
	}

protected:
	lua_State * m_Lua = nullptr;
};

template <typename T>
class Luna 
{
public:

    static void Register(lua_State* L)
	{
	 	//注册函数，在lua中创建function类型的值来表示Luna<T>::constructor
		lua_pushcfunction(L, &Luna::Constructor);

		//该函数并将类型为fucntion的值入栈
		//将上面的function值赋给全局变量className
		lua_setglobal(L, T::className);

		//创建一个新表（将用作metatable），将新表放到栈顶并建立表和registry中类型名的联系。
		//这个关联是双向的：使用类型名作为表的key；
		//同时使用表作为类型名的key（这种双向的关联，使得其他的两个函数的实现效率更高）。
		luaL_newmetatable(L, T::className);
		/*
		Lua以__gc元方法的方式提供了finalizers。这个元方法只对userdata类型的值有效。
		当一个userdatum将被收集的时候，并且usedatum有一个__gc域，
		Lua会调用这个域的值（应该是一个函数）：以userdatum作为这个函数的参数调用。
		这个函数负责释放与userdatum相关的所有资源。
		*/
		lua_pushstring(L, "__gc");
		lua_pushcfunction(L, &Luna::GCObj);
		lua_settable(L, -3);

		// 把方法也注册进userdata的元表里
		for (int i = 0; T::Functions[i].name; ++i)
		{
			lua_pushstring(L, T::Functions[i].name);
			lua_pushnumber(L, i);
			lua_pushcclosure(L, &Luna::Proxy, 1);
			lua_settable(L, -3);
		}

		// 注册__index方法
		lua_pushstring(L, "__index");
		lua_pushvalue(L, -2);
		lua_settable(L, -3);
	}

    static int Constructor(lua_State *L)
	{
		T* obj = new T(L);

		lua_newtable(L);

		lua_pushnumber(L, 0);
		//void *lua_newuserdata (lua_State *L, size_t size);
		T** a =  static_cast<T **>(lua_newuserdata(L, sizeof(T*)));
		
		*a = obj;
		//void  luaL_getmetatable (lua_State *L, const char *tname);
		//函数获取registry中的tname对应的metatable。
		luaL_getmetatable(L, T::className);
		//lua_setmetatable函数将表(get到的)出栈，并将其设置为给定位置(上面userdatum)对象的metatable。
		lua_setmetatable(L, -2);


		return 1;
	}
    static int Proxy(lua_State *L)
	{
		int i = (int)lua_tonumber(L, lua_upvalueindex(1));
		T **obj = static_cast<T **>(luaL_checkudata(L, 1, T::className));
		lua_remove(L, 1);
		return ((*obj)->*(T::Functions[i].mfunc))(L);
	}

    static int GCObj(lua_State *L)
	{
		T **obj = static_cast<T **>(luaL_checkudata(L, 1, T::className));
		delete (*obj);
		return 0;
	}
};

}

#endif // __LUA_WRAPPER_H__
