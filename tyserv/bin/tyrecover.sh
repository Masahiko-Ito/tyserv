#! /bin/sh
#
DEF_TYSERV_DIR=${HOME}/tyserv
DEF_TYSERV_RUNDIR=${HOME}/rundir1
TYSERV_RUNDIR=${DEF_TYSERV_RUNDIR}
#
if [ X"$1" = "X-h" -o X"$1" = "X--help" ]
then
    echo "usage : `basename $0` [-d tyserv_rundir] [-s|--stdin] [-v|--verbose] [-f|--force]"
    echo " recover database from recovery journal"
    echo " option : -d DIRECTORY    DIRECTORY has recovery journal and tyserv.conf"
    echo "                          (default ${TYSERV_RUNDIR})"
    echo "          -s, --stdin     read recovery journal from stdin"
    echo "          -v, --verbose   verbose mode"
    echo "          -f, --force     force recover to end of recovery journal"
    exit 1
fi
#
STDIN_SW=""
VERBOSE_SW=""
FORCE_SW=""
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
    -f|--force )
        FORCE_SW="on"
        ;;
    esac
    shift
done
#
if [ "X${STDIN_SW}" = "X" ]
then
    RVJ=${TYSERV_RUNDIR}/journal/rvj.dat
    if [ ! -r ${RVJ} ]
    then
        if [ "X${VERBOSE_SW}" != "X" ]
        then
            echo "tyrecover failure. recovery jounal(${RVJ}) can not read."
        fi
        exit 1
    fi
else
    RVJ=""
fi
#
if [ "X${VERBOSE_SW}" != "X" ]
then
    echo "tyrecover start. recovery jounal=(${RVJ}), run directory=(${TYSERV_RUNDIR})."
fi
#
lastline=`cat -n ${RVJ} |\
          egrep -i '^ *[0-9]*	commit|^ *[0-9]*	end_tran' |\
          tail -1 |\
          sed -e 's/^ *//;s/	.*$//'`
export lastline
#
if [ "Xon" = "X${FORCE_SW}" ]
then
    cat ${RVJ} |\
    egrep -v -i '^commit|^end_tran' |\
    ${DEF_TYSERV_DIR}/bin/tyrecover 0 ${TYSERV_RUNDIR}
#                                   ^ ^tyserv directory
#                                   ^when 0, don't output recovery journal
    STAT=$?
else
    cat -n ${RVJ} |\
    sed -e 's/^ *//' |\
    gawk 'BEGIN{
        FS="\t"
    }
    {
        if ($1 <= ENVIRON["lastline"]){
            gsub(/^[0-9]*\t/, "");
            print $0;
        }
    }' |\
    egrep -v -i '^commit|^end_tran' |\
    ${DEF_TYSERV_DIR}/bin/tyrecover 0 ${TYSERV_RUNDIR}
#                                   ^ ^tyserv directory
#                                   ^when 0, don't output recovery journal
    STAT=$?
fi
#
if [ "X${VERBOSE_SW}" != "X" ]
then
    if [ "X${STAT}" = "X0" ]
    then
        echo "tyrecover success. status=${STAT}."
    else
        echo "tyrecover failure. status=${STAT}."
    fi
fi
#
exit ${STAT}
