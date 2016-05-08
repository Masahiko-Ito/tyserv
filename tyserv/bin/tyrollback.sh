#! /bin/sh
#
if [ X"$1" = "X-h" -o X"$1" = "X--help" ]
then
    echo "usage : `basename $0` [-d tyserv_rundir] [-stdin]"
    echo " rollback database from rollback journal"
    exit 1
fi
#
DEF_TYSERV_DIR=/home/tyserv/tyserv
DEF_TYSERV_RUNDIR=/home/tyserv/rundir1
TYSERV_RUNDIR=${DEF_TYSERV_RUNDIR}
#
STDIN_SW=""
#
while [ "$#" != "0" ]
do
    case $1 in
    -d )
        shift
        TYSERV_RUNDIR=$1
        ;;
    -stdin )
        STDIN_SW=$1
        ;;
    esac
    shift
done
#
TAC=/usr/bin/tac
#
if [ "X${STDIN_SW}" = "X-stdin" ]
then
    if [ -x ${TAC} ]
    then
        ${TAC} |\
        ${DEF_TYSERV_DIR}/bin/tyrecover 1 ${TYSERV_RUNDIR}
#                                       ^ ^tyserv directory
#                                       ^when 1, output recovery journal
        exit 0
    else
        exit 1
    fi
else
    if [ -r ${TYSERV_RUNDIR}/journal/rbj.dat ]
    then
        if [ -x ${TAC} ]
        then
            ${TAC} ${TYSERV_RUNDIR}/journal/rbj.dat |\
            ${DEF_TYSERV_DIR}/bin/tyrecover 1 ${TYSERV_RUNDIR}
#                                           ^ ^tyserv directory
#                                           ^when 1, output recovery journal
            exit 0
        else
            exit 1
        fi
    else
        exit 1
    fi
fi
