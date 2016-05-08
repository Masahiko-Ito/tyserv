#! /bin/sh
if [ "X${TYPHOON_DIR}" = "X" ]
then
    TYPHOON_DIR=/usr/local/typhoon;export TYPHOON_DIR
fi
#
if [ "X${TYPHOON_DB}" = "X" ]
then
    TYPHOON_DB=typhoondb;export TYPHOON_DB
fi
#
if [ "X${TYSERV_DIR}" = "X" ]
then
    TYSERV_DIR=/usr/local/tyserv;export TYSERV_DIR
fi
#
INITFILE=${TYSERV_DIR}/conf/tyserv.conf
#
if [ X"$1" = "X-h" -o X"$1" = "X--help" ]
then
    echo "usage : `basename $0`"
    echo " rollback database from stdin(rollback journal)"
    exit 1
fi
#
if [ -r ${TYSERV_DIR}/journal/rbj.dat ]
then
##    /bin/cat -n ${TYSERV_DIR}/journal/rbj.dat |\
##    /usr/bin/sort -n -r |\
##    /usr/bin/sed -e 's/^ *[0-9]*	*//g' |\
###                               ^TAB
##    ${TYSERV_DIR}/bin/tyrecover 1
###                               ^when 1, output recovery journal
    if [ -x /usr/bin/tac ]
    then
        /usr/bin/tac ${TYSERV_DIR}/journal/rbj.dat |\
        ${TYSERV_DIR}/bin/tyrecover 1
#                                   ^when 1, output recovery journal
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi

