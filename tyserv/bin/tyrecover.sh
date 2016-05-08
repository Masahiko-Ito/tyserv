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
    echo "usage : `basename $0` [-]"
    echo " recover database from stdin or recovery journal"
    exit 1
fi
#
case X"$1" in
X-)
    rvj=""
    ;;
X)
    rvj=${TYSERV_DIR}/journal/rvj.dat
    ;;
*)
    rvj="$1"
    ;;
esac
#
/bin/cat ${rvj} |\
/bin/egrep -v -i '^commit|^end_tran' |\
${TYSERV_DIR}/bin/tyrecover 0
#                           ^when 0, don't output recovery journal
