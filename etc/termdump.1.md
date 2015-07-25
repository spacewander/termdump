% TERMDUMP(1) Termdump User Manuals
% spacewander <spacewanderlzx@gmail.com>
% Jul 17, 2015

# NAME
termdump -- Dump your pty session and replay it

# SYNOPSIS

termdump [*option*] [*session*]

# DESCRIPTION

Dump your (pseudo)terminal session and replay it. You can use it to bootstrap daily work.

# OPTIONS

-h, --help
:   output usage information

-i, --init
:   initialize configure interactively

-e, --edit *session*
:   edit session

-d, --delete *session*
:   delete session

-s, --save *session*
:   save session

-l, --list
:   list all sessions

-v, --version
:   print version

If you run `termdump` with a session name only, it will replay the session.

*session* can be a session file(currently in yml format) in `~/.config/termdump/session`, or in the current working directory, or an absolute path to the session file.

# SAVE OPTIONS

--stdout
:   print dump result to stdout while saving a session

--exclude
:   exclude current pty while saving a session

# EXAMPLE

At the first time you use this tool, you may need to run `termdump -i` to set up configure.

Then you can run `termdump -s [--exclude]` to save your current pty session.

Run `termdump -l` to list all saved sessions, `termdump -e` to edit one, and `termdump -d` to delete one.

To replay your session, you can run `termdump [session]`.

# REPORTING BUGS

<https://github.com/spacewander/termdump/issues>
