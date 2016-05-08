#! /bin/sh
#
if [ X"$1" = "X-h" -o X"$1" = "X--help" ]
then
    echo "usage : `basename $0` [-d tyserv_rundir] [-stdin]"
    echo " recover database from recovery journal"
    exit 1
fi
#
DEF_TYSERV_DIR=${HOME}/tyserv
DEF_TYSERV_RUNDIR=${HOME}/rundir1
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
if [ "X${STDIN_SW}" = "X-stdin" ]
then
    RVJ=""
else
    RVJ=${TYSERV_RUNDIR}/journal/rvj.dat
fi
#
cat ${RVJ} |\
egrep -v -i '^commit|^end_tran' |\
${DEF_TYSERV_DIR}/bin/tyrecover 0 ${TYSERV_RUNDIR}
#                               ^ ^tyserv directory
#                               ^when 0, don't output recovery journal
