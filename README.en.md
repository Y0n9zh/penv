# penv

> One command to prepare a Python virtual environment for the current project and open a CMD window with it activated.

Windows has no per-directory environment and no `direnv` out of the box. `penv` fills that gap with a single batch file:

```cmd
cd C:\code\myproject
penv
```

It creates `.venv` if missing, reuses it otherwise, and opens a new CMD window where `python` and `pip` already point at the project virtualenv.

## Install

```cmd
git clone https://github.com/<your-name>/penv.git
cd penv
install.cmd
```

Open a **new** terminal afterwards. `install.cmd` copies `penv.cmd` into `%USERPROFILE%\bin` and adds that directory to your user `PATH`.

Manual install: drop `penv.cmd` into any directory that is already on `PATH`.

Uninstall: `uninstall.cmd`.

## Usage

| Command | Description |
|---|---|
| `penv` | ensure `.venv` exists, open a new CMD window with it |
| `penv show` | print resolved root, `VIRTUAL_ENV`, variables and effective `PATH` |
| `penv run <cmd>` | run a command in the current window with the environment applied |
| `penv venv` | only create/verify `.venv`, no window |
| `penv init` | create a `.env` template in the current directory |
| `penv version` | print version |
| `penv help` | show help |

## How it works

1. Walk up from the current directory: nearest `.env`, else nearest `.venv`, else the current directory becomes the project root.
2. Create `.venv` there if it does not exist.
3. Prepend `.venv\Scripts` to `PATH`.
4. `start cmd /k` a new window in that directory.

The child process inherits the environment block; nothing is written to the registry and nothing leaks after the window closes.

## `.env` (optional)

```ini
# comments must start with # at column 1
KEY=VALUE          set a variable
PATH+=DIR          prepend DIR to PATH
```

Values are literal (no quotes, no `%VAR%` expansion). Relative `PATH+=` entries resolve against the `.env` directory.

## Why pure ASCII + CRLF

`cmd.exe` re-reads a batch file using the active code page; switching it mid-file desyncs the parser, and LF-only endings break `goto :label` resolution. Both produce bizarre "fragments executed as commands" errors. `.gitattributes` enforces CRLF for `*.cmd`.

## License

[MIT](LICENSE)
