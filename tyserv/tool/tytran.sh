#! /bin/sh
#
DEF_TYSERV_DIR=/home/tyserv/tyserv
#
if [ X"$1" = "X-h" -o X"$1" = "X--help" ]
then
    echo "usage : `basename $0` [-s server|--server server] [-p port|--port port] [-n|-ngexit] [-v|--verbose]"
    echo " execute transaction in batch mode from stdin"
    echo " option : -s server       connect to server. default localhost."
    echo "          -p port         connect to port. default 20000."
    echo "          -n, --ngexit    exit when NG status"
    echo "          -v, --verbose   verbose mode"
    exit 1
fi
#
SERVER="localhost"
PORT="20000"
NGEXIT_SW="0"
VERBOSE_SW="0"
#
while [ "$#" != "0" ]
do
    case $1 in
    -s|--server )
        shift
        SERVER=$1
        ;;
    -p|--port )
        shift
        PORT=$1
        ;;
    -n|--ngexit )
        NGEXIT_SW="1"
        ;;
    -v|--verbose )
        VERBOSE_SW="1"
        ;;
    esac
    shift
done
#
grep -v '^#' |\
${DEF_TYSERV_DIR}/bin/tytran ${SERVER} ${PORT} ${NGEXIT_SW} ${VERBOSE_SW}
STAT=$?
exit ${STAT}
