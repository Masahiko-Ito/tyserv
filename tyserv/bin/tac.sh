#! /bin/sh
cat -n $* |\
sort -n -r |\
sed -e 's/^ *[0-9]*	*//g'
#                  ^TAB
