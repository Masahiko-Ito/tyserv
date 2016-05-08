#! /bin/sh
#
DEF_TYSERV_DIR=/home/tyserv/tyserv
DEF_TYSERV_RUNDIR=/home/tyserv/rundir1
TYSERV_RUNDIR=${DEF_TYSERV_RUNDIR}
#
if [ -x /usr/bin/tac ]
then
#
# for Linux etc
#
    TAC=/usr/bin/tac
else
#
# for FreeBSD etc
#
    TAC=${DEF_TYSERV_DIR}/bin/tac.sh
fi
#
if [ X"$1" = "X-h" -o X"$1" = "X--help" ]
then
    echo "usage : `basename $0` [-d tyserv_rundir] [-s|--stdin] [-v|--verbose]"
    echo " rollback database from rollback journal"
    echo " option : -d DIRECTORY    DIRECTORY has rollback journal and tyserv.conf"
    echo "                          (default ${TYSERV_RUNDIR})"
    echo "          -s, --stdin     read rollback journal from stdin"
    echo "          -v, --verbose   verbose mode"
    exit 1
fi
#
STDIN_SW=""
VERBOSE_SW=""
#
while [ "$#" != "0" ]
do
    case $1 in
    -d )
        shift
        TYSERV_RUNDIR=$1
        ;;
    -s|--stdin )
        STDIN_SW=$1
        ;;
    -v|--verbose )
        VERBOSE_SW=$1
        ;;
    esac
    shift
done
#
if [ "X${STDIN_SW}" = "X" ]
then
    RBJ=${TYSERV_RUNDIR}/journal/rbj.dat
    if [ ! -r ${RBJ} ]
    then
        if [ "X${VERBOSE_SW}" != "X" ]
        then
            echo "tyrollback failure. rollback jounal(${RBJ}) can not read."
        fi
        exit 1
    fi
else
    RBJ=""
fi
#
if [ "X${VERBOSE_SW}" != "X" ]
then
    echo "tyrollback start. rollback jounal=(${RBJ}), run directory=(${TYSERV_RUNDIR})."
fi
#
if [ -x ${TAC} ]
then
    ${TAC} ${RBJ} |\
    ${DEF_TYSERV_DIR}/bin/tyrecover 1 ${TYSERV_RUNDIR}
#                                   ^ ^tyserv directory
#                                   ^when 1, output recovery journal
    STAT=$?
    if [ "X${VERBOSE_SW}" != "X" ]
    then
        if [ "X${STAT}" = "X0" ]
        then
            echo "tyrollback success."
        else
            echo "tyrollback failure. status=${STAT}."
        fi
    fi
    exit ${STAT}
else
    if [ "X${VERBOSE_SW}" != "X" ]
    then
        echo "tyrollback failure. ${TAC} can not be executed"
    fi
    exit 1
fi
