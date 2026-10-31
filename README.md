# penv

> 一条命令，给当前项目准备好 Python 虚拟环境，并打开一个已经激活它的 CMD 窗口。

Windows 没有「目录级环境变量」，也没有开箱即用的 `direnv`。`penv` 用最简单的方式补上这个缺口：

```cmd
cd C:\code\myproject
penv
```

没有 `.venv` 就自动建一个，有就直接用，然后打开一个新的 CMD 窗口 —— 里面的 `python` 和 `pip` 已经指向本项目的虚拟环境。

## 它做了什么

1. 从当前目录逐级向上，确定项目根目录（最近的 `.env` → 最近的 `.venv` → 当前目录）
2. 根目录下没有 `.venv` 就创建（首次约 10 秒）
3. 把 `.venv\Scripts` 前置到 `PATH`
4. 打开一个新的 `cmd.exe` 窗口，工作目录设为项目根

## 特性

- **单个 `.cmd` 文件**，除 Python 外无任何依赖，不需要 PowerShell 脚本执行策略
- **不需要 `activate.bat`**：venv 直接进 PATH，窗口里敲 `pip install` 就是装进项目
- **子目录自动复用**：在 `项目\src\utils\` 里敲 `penv`，用的还是项目根的 `.venv`
- **可选 `.env`**：需要额外环境变量（`JAVA_HOME`、`PATH+=` 等）时再 `penv init`
- **纯 ASCII + CRLF**：任何终端、任何代码页下都不会解析错乱（原因见文末）

## 安装

### 一键安装

```cmd
git clone https://github.com/<your-name>/penv.git
cd penv
install.cmd
```

然后**新开一个终端**，输入 `penv` 验证。

安装脚本会把 `penv.cmd` 复制到 `%USERPROFILE%\bin`，并把该目录加入当前用户的 `PATH`。

### 手动安装

把 `penv.cmd` 复制到任意已经在 `PATH` 中的目录即可。

### 卸载

```cmd
uninstall.cmd
```

## 用法

| 命令 | 说明 |
|---|---|
| `penv` | 确保 `.venv` 存在，打开带环境的 CMD 窗口 |
| `penv show` | 打印解析出的根目录、`VIRTUAL_ENV`、变量和生效后的 `PATH` |
| `penv run <命令>` | 在当前窗口带着这套环境执行命令，如 `penv run python -V` |
| `penv venv` | 只创建/检查 `.venv`，不开窗口（适合脚本、CI） |
| `penv init` | 在当前目录生成 `.env` 模板 |
| `penv version` | 版本号 |
| `penv help` | 帮助 |

### 典型工作流

```cmd
cd C:\code\myproject
penv
pip install requests
python main.py
```

### 配合额外环境变量

```cmd
penv init          :: 生成 .env，按需编辑
penv               :: 打开窗口后 JAVA_HOME 等已生效
```

## `.env` 语法

```ini
# 注释必须以 # 开头，不能有前导空格
KEY=VALUE          设置一个环境变量
PATH+=DIR          把 DIR 前置到 PATH
```

规则：

1. 值按**字面量**处理：不要加引号，也不支持 `%USERPROFILE%` 这类变量展开
2. `PATH+=` 可以写相对路径，会相对于 `.env` 所在目录解析
3. 空行和 `#` 开头的行会被忽略

示例：

```ini
JAVA_HOME=C:\Program Files\Java\jdk-17
PATH+=.\tools\bin
PROJECT_ROOT=C:\code\demo
```

参考 [examples/.env.example](examples/.env.example)。

## 工作原理

`penv.cmd` 在**当前进程**里设置环境变量，然后 `start cmd /k` 派生子进程 —— Windows 的子进程会完整继承父进程的环境块。窗口关闭后什么都不会留下，不污染系统。

之所以要这么做，是因为 Windows 的 `HKCU\Environment` 是**用户级/机器级**的，没有「进入某个目录就生效」的机制。改注册表既麻烦又全局生效，用一次性子进程才是正确做法。

## 常见问题

**Q：提示 `python` 不是内部或外部命令 / 只弹微软商店**

你的 `python` 可能只是 Microsoft Store 的「应用执行别名」桩（0 字节）。用 `where python` 检查，安装真正的 Python 后新开终端。

**Q：venv 建到了上级目录，不是当前目录**

因为上面某一级存在 `.env`，它被当作项目根。这是有意设计：同一项目下的子目录共用一套环境。删掉那个 `.env` 即可改变边界。

**Q：为什么脚本里全是英文、还必须是 ASCII**

`cmd.exe` 读取批处理文件时按**当前代码页**逐行解析，并在执行 `chcp` 后继续用新代码页读后续字节，位置会错位。混合非 ASCII 字符 + 切码页会让后面的行被截断或拼错，现象是「文件里的片段被当成命令执行」，极难排查。同理，**LF 换行也会让 `goto :label` 定位错乱**。所以本项目强制：纯 ASCII + CRLF，由 `.gitattributes` 保证。

**Q：和 conda / 全局 Python 冲突吗**

不冲突。`penv` 只把 `.venv\Scripts` 前置进当前子进程的 `PATH`，退出窗口即失效。如果某个项目需要 conda，在该目录的 `.env` 里用 `PATH+=` 指向 conda 环境即可。

**Q：能用在 PowerShell 里吗**

能调用，但打开的是 `cmd.exe`。脚本本身只用 `cmd` 内建命令。

## 开发说明

- 脚本必须保持 **纯 ASCII + CRLF**（`.gitattributes` 已配置）
- 修改后至少要测：首次建 venv、重复执行、子目录解析、`penv run`
- 版本号位于 `penv.cmd` 头部与 `:do_version`

## License

[MIT](LICENSE)
