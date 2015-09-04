# termdump

[![Build Status](https://travis-ci.org/spacewander/termdump.svg?branch=master)](http://travis-ci.org/spacewander/termdump)

Dump your (pseudo)terminal session and replay it. You can use it to bootstrap daily work.

## Usage

```shell
Usage: termdump [options] [session]
    -i, --init                       initialize configure interactively
    -e, --edit [session]             edit session
    -d, --delete [session]           delete session
    -s, --save [session]             save session
        --stdout                     print dump result to stdout while saving a session
        --exclude                    exclude current pty while saving a session
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
Enter a new session name:
# or `termdump -s mydailywork --exclude`
# if you want to exclude the pty running this command
```

### load a session

```shell
$ termdump mydailywork
```

or

```shell
$ termdump
order:  session name    ctime               atime
[0]:        scutmall    2015-07-01 17:07:37 2015-07-25 11:59:42
[1]:        mydailywork 2015-07-19 11:05:52 2015-07-25 11:22:03
[2]:        termdump    2015-06-30 10:58:20 2015-07-25 11:21:46
Select one session to load:1
```

### edit a session

```shell
$ termdump -e mydailywork
```

or

```shell
$ termdump -e
order:  session name    ctime               atime
[0]:        scutmall    2015-07-01 17:07:37 2015-07-25 11:59:42
[1]:        mydailywork 2015-07-19 11:05:52 2015-07-25 11:22:03
[2]:        termdump    2015-06-30 10:58:20 2015-07-25 11:21:46
Select one session to edit:1
```

### delete a session

```shell
$ termdump -d mydailywork
```

or

```shell
$ termdump -d
order:  session name    ctime               atime
[0]:        scutmall    2015-07-01 17:07:37 2015-07-25 11:59:42
[1]:        mydailywork 2015-07-19 11:05:52 2015-07-25 11:22:03
[2]:        termdump    2015-06-30 10:58:20 2015-07-25 11:21:46
Select one session to delete:1
```

### list all session

```shell
$ termdump -l
# equal to run `termdump`
```

Read more in [session syntax and examples](sessions.md) and [configure](configure.md).

## Supported terminal

- [x] gnome-terminal
- [x] guake
- [x] konsole
- [x] terminator
- [x] tilda
- [x] urxvt
- [ ] xfce4-terminal
- [x] xterm
- [ ] yakuake

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
