在 windows 上使用 vi 操作某些 app 提高效率

# ViATc

`ViATc` 可以在 `Total Commander` 中使用 `vi`， 来源于开源项目 ([linxinhong/ViATc](https://github.com/linxinhong/ViATc))，在它基础上做了个性化配置，功能比较多不列举，主要有以下差异：
-  `h/l` 光标在左右窗口跳转
- `Ctrl+u / Ctrl+d` 上移/下移 15个文件
- 去掉 `WIN + e` 快捷键，恢复 `Windows` 默认行为（打开资源管理器）
- `Shift+h / Shift+l` 切换上一个/下一个标签（左侧/右侧标签）
- `gn / gm` 切换上一个/下一个标签（左侧/右侧标签）

# ViAtBc

以 `viatc` 作为模版创建的针对 `Beyond Compare` 应用程序的 `vi` 热键，功能比较简单，主要是光标导航
- `i` 进入 `insert` 模式，该模式下就是正常的 `Beyond Compare` 操作(*重命名需要进入该模式*)
- `Esc` 按键进入 `normal` 模式，在该模式下进行 `vi` 操作
- `h/l` 光标在左右窗口跳转
- `j/k` 光标上下移动
- `shift + j/k` 上下移动并选中文件
- `Ctrl+u / Ctrl+d` 上移/下移 15个文件
- `x` 删除光标所在文件或者删除选中的文件
- `gg` 光标跳转到最上面
- `G` 制光标跳转到最下面

# 如何使用

1. 下载 [AutoHotkey](https://www.autohotkey.com/)
2. 点击 `ViATc\viatc-0.6.1.ahk` 即可使用 `vi` 操作 `total commander`
3. 点击 `ViAtBC\ViAtBC.ahk` 即可使用 `vi` 操作 `total commander`

运行 `ahk` 脚本后，任务栏里会有个绿色的 `H` 小图标

## 配置 viatbc

`ViAtBc` 下有个 `viabc.ini` 配置文件，里面的 `BCClass` 用于配置 `Beyond Compare` 窗口类名，通过一下方式可以获取到
1. 打开 `AHK` 自带的 `Window Spy`（`AutoHotkey` 安装目录下的 `AU3_Spy.exe`）
    - `Window Spy` 也可以通过右击任务栏的绿色 `H` 小图标启动
2. 点击 BC 窗口，看顶部的 ahk_class 是什么值
3. 把这个值写入到 `ini` 文件即可

## 转换成 exe

使用 `AHK` 自带的 `Ahk2Exe.exe` 可以将 `ank` 脚本转换成 `exe` 文件，比较方便创建快捷键方式放到系统启动项中