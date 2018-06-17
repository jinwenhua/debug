# vscode-l-debug
***
vs code lua 调试插件适配器   
基于lua5.3 写的，其他的 lua5.x 应该也是支持可。   
如果有问题需要改动的地方也不会很多。  
这个是windows版本的，其他系统暂时不支持。    

第一次写 vscode 的调试适配器，会有很多问题，欢迎指正。

***

### 编译生成 ldebugserver.dll   

1. 在根目录创建 biuld 目录，使用 cmake 让生成的工程在 build 目录里面。   

2. lib 目录里面放的是lua.lib，我上传的是 lua5.3 的 64位的版本。如果需要其他版本的，需要自己编对应的版本，并替换掉。在编译自己版本的lua.lib的时候需要注意，要加上宏定义：LUA_USE_WINDOWS 和 LUA_DL_DLL

3. ldebugserver依赖于lua.lib。

4. 把编译好的 ldebugserver.dll 放到 script\\debuger目录下。

5. ldebugserver.dll 需要有 lua.dll， 如果你的客户端程序不是同过lua.dll 加载 lua 的，而是整个源码嵌入的。需要编对应的 lua.dll 版本并放到 script\\debuger 目录下。

### 部署 debuger 
1. 在编译生成 ldebugserver.dll 这个步骤完成后，就可以把 script 下的 debuger 文件夹复制到你的客户端根目录下，或者客户端lua脚本根目录下。

2. 在你的客户端脚本初始化的时候，把 debuger\\init.lua 文件require进去。

3. 在程序主循环里面调用 ldb_mrg:on_tick(l_debug.DEBUG_MODE_RUN)， 你可以自己控制调用的频率，建议是100毫秒一次，最好好不要超过1秒。

### vscode 配置
1. 安装 Lua Debug 插件（其实也可以不用装，方便配置而已）。

2. 打开调试配置 launch.json 文件。方法如下：   
![Aaron Swartz](https://github.com/lhswei/vscode-l-debug/blob/debug-server/res/launch_json.PNG)
3. 在点击添加配置，选择 lua attach。然后修改配置：   
![Aaron Swartz](https://github.com/lhswei/vscode-l-debug/blob/debug-server/res/launch_attach.PNG)
```
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "lua attach",  // 调试名称: 可以自定义
            "type": "lua",         // 调试类型: lua 
            "request": "attach",   // 调试方式: attach
            "stopOnEntry": false,  // 这里设置成 false
            "ip": "127.0.0.1",     // 本地调试

            // debugserver 的监听端口，要与 debuger\\init.lua 中 
            //local port = 8869;
            //ldb_mrg:init(port, 0);
            "port": 8869,

            // 客户端程序的工作目录(client.exe所在的目录)
            "workingPath": "e:\\github\\vscode-l-debug\\"
        }
    ]
}
```

### 进行调试
1. 安装 “部署 debuger” 所说的配置。 启动客户端。

2. 点击选择 “vscode 配置” 中的 “lua attach” 启动调试。   
![Aaron Swartz](https://github.com/lhswei/vscode-l-debug/blob/debug-server/res/lua_attach.PNG)
3. 如果链接上了 debugserver 技能正常下断点了。

4. debugserver 是调试服务器，会建立 socket 监听 vscode 的链接请求。建立连接成功后，进可以进行调试通信了。


### lua hook 优化
1. 由于 debug.sethook 的行模式（line）会对性能消耗很大，所以在没有断点的时候，是没有hook函数的。

2. 设置断点后，一开始的hook函数是 call 么模式，只有进入断点所在的函数之后才会进入 line 模式。离开断点所在的函数之后，又变会 call 模式。

3. 在断点所在的函数里面，进入其他函数调用，会进入 call 和 return 同时进行的模式。

4. 上面只是大体的思想，实现的细节可能会有些出入。

