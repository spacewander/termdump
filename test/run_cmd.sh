#!/bin/sh

# test features which can't be tested automatically
script="../bin/termdump"
"$script" -s # save and ask for a name
"$script" -e # edit one
"$script" # load one
"$script" -d # delete one
