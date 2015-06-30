# termdump

[![Build Status](https://travis-ci.org/spacewander/termdump.svg?branch=master)](http://travis-ci.org/spacewander/termdump)

Dump your (pseudo)terminal session and replay it. You can use it to bootstrap daily work.

## Usage

```shell
$ termdump -h
Usage: termdump [options] [session]
    -e, --edit [session]             edit session
    -d, --delete [session]           delete session
    -s, --save [session]             save session
    -i, --init                       initialize configure interactively
        --stdout                     print dump result to stdout
        --exclude                    exclude current pty
    -l, --list                       list all sessions
    -v, --version                    print version
```

### initialize configure

```shell
$ termdump -i
```

### dump a session

```shell
$ termdump -s mydailywork
# or `termdump -s mydailywork --exclude`
# if you want to exclude the pty running this command
```

### load a session

```shell
$ termdump mydailywork
```

### edit a session

```shell
$ termdump -e mydailywork
```

### delete a session

```shell
$ termdump -d mydailywork
```

Read more in [session syntax and examples](sessions.md) and [configure](configure.md).

## Supported terminal

- [x] gnome-terminal
- [x] terminator
- [x] xterm
- [ ] guake
- [ ] urxvt
- [ ] konsole
- [ ] xfce4-terminal

If you want to support Terminal X, you can write a terminal file under
https://github.com/spacewander/termdump/tree/master/lib/termdump/terminal and then send me a pr.
Currently there is not a plan to support terminals in OS X platform, since I don't have OS X to test with.
If you want to implement one, you may need to use [cliclick](https://github.com/BlueM/cliclick) instead of `xdotool`.

## Requirements

Current requirements are `ps` and `xdotool`.
We use `ps` to get the result of terminal session, and `xdotool` to emulate typing.

`ps` has been shipped with your OS probably.
You can install `xdotool` via [this guide](http://www.semicomplete.com/projects/xdotool/#idp9392).

## Video

TODO
