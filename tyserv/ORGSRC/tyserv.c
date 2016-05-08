/*
 * __MESSAGE__
 *
 * tyhpoon database server program by M.Ito
 * Ver. 1.0    2002.07.01
 */
#include <stdio.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <unistd.h>

#include <tcpd.h>
#include <syslog.h>
extern int hosts_clt();
char ipstr[16];
int allow_severity = LOG_INFO;
int deny_severity = LOG_WARNING;

#include <ctype.h>
#include <typhoon.h>

/* DataBase definition */
#define  DATABASE_NAME "typhoondb"
#include "typhoondb.h"

#define BUF_LEN (1024 * 16)
#define PATH_LEN (256)
#define NULL_STR "";
#define FALSE 0;
#define TRUE !FALSE;

#define DEF_HOST "localhost"
#define DEF_PORT ((unsigned short)20000)
#define DEF_SOCKET_WAIT_QUEUE (32)
#define DEF_TYPHOON_DIR  "/home/tyserv/typhoon"
#define DEF_TYSERV_DIR  "/home/tyserv/tyserv"
#define DEF_TYSERV_RUNDIR  "/home/tyserv/rundir1"
#define DEF_RVJ_SW (1)
#define DEF_RBJ_SW (1)
#define DEF_SAFER_SW (1)
#define DEF_DAEMON_NAME "tyserv"
#define DEF_DEBUG (0)

char Host_name[PATH_LEN];
unsigned short Socket_port;
int  Socket_wait_queue;
char Dbd_dir[PATH_LEN];
char Data_dir[PATH_LEN];
char Rvj_name[PATH_LEN];
char Rbj_name[PATH_LEN];
char Passwd_name[PATH_LEN];
char Daemon_name[PATH_LEN];
char Tyserv_dir[PATH_LEN];
char Tyserv_rundir[PATH_LEN];
char Conf_file[PATH_LEN];
int  Rvj_sw;
int  Rbj_sw;
int  Safer_sw;
int  Debug;

FILE *Fp_rvj;
FILE *Fp_rbj;
FILE *Fp_passwd;

char Rollback_script[PATH_LEN];

int  S_waiting, S_sock;
char Tmp_buf[BUF_LEN];
char In_buf[BUF_LEN];
char In_buf_rvj[BUF_LEN];
char Out_buf[BUF_LEN];
char Out_buf_rbj[BUF_LEN];
char Pw_buf[BUF_LEN];

int  IsGranted;
int  Sigchld_cnt = 0;

void  SigTrap();

int  init_file();

int  sock_read();
int  sock_write();

int  get_func_rec();
char *FuncName;
char *RecName;
char Table_list[BUF_LEN];
char Table_name[PATH_LEN];

int  get_key_cond();
char *KeyName;
char *Condition;

int  get_keyvalue();
char *KeyValue;

int  get_item_value();
char *ItemName;
char *ItemValue;

#define __TYSERV_PART1__
#include "tyserv.h"

struct {
    char *recname;
    int  (*func_get)();
    int  (*func_put)();
    int  (*func_update)();
    int  (*func_delete)();
    int  (*func_getnext)();
} Tbl_rec[] = {

#undef  __TYSERV_PART1__
#define __TYSERV_PART2__
#include "tyserv.h"

    {NULL, NULL}
};

int main(argc, argv)
    int  argc;
    char *argv[];
{
    struct hostent *myhost;
    struct sockaddr_in me;
    struct sockaddr_in caddr;
    socklen_t caddr_len;

    int  i, ret, fd, status, access_allow;

/*
 * set signal trap
 */
    signal(SIGHUP, SigTrap);
    signal(SIGTERM, SigTrap);
    signal(SIGCHLD, SigTrap);

    signal(SIGINT, SIG_IGN);
    signal(SIGPIPE, SIG_IGN);
    signal(SIGQUIT, SIG_IGN);
    signal(SIGTSTP, SIG_IGN);
    signal(SIGTTIN, SIG_IGN);
    signal(SIGTTOU, SIG_IGN);
    signal(SIGTTOU, SIG_IGN);

/*
 * set initial environment 
 */
    if ((fd = open("/dev/tty", O_RDWR)) >= 0){
        ioctl(fd, TIOCNOTTY, (char *)NULL);
        close(fd);
    }
    chdir("/");
    umask(022);
    close(0);
    errno = 0;

/*
 * set from initialze file
 */
    if (argc < 2){
        fprintf(stderr, "usage : %-s TYSERV_RUNDIR\n", argv[0]);
        exit(1);
    }

    if (argv[1][0] == '\0'){
        strncpy(Tyserv_rundir, DEF_TYSERV_RUNDIR, (sizeof Tyserv_rundir) - 1);
    }else{
        strncpy(Tyserv_rundir, argv[1], (sizeof Tyserv_rundir) - 1);
    }

    init_file();

/*
 * data base open check
 */
    if (DB_open() < 0){
        fprintf(stderr, Out_buf);
        fprintf(stderr, " crashed\n");
        exit(1);
    }
    DB_close();

/*
 * make socket
 */
    if ((myhost = gethostbyname(Host_name)) == (struct hostent *)NULL){
        fprintf(stderr, "can't gethostbyname(%-s), crashed.\n", Host_name);
        exit(1);
    }
    bzero((char *)&me, sizeof me);
    me.sin_family = AF_INET;
    me.sin_port = htons(Socket_port);
    bcopy(myhost->h_addr, (char *)&me.sin_addr, myhost->h_length);

/*
 * ready socket
 */
    if ((S_waiting = socket(AF_INET, SOCK_STREAM, 0)) == -1){
        fprintf(stderr, "can't create socket : %s\n", strerror(errno));
        exit(1);
    }
    if (bind(S_waiting, (struct sockaddr *)&me, sizeof me) == -1){
        fprintf(stderr, "can't bind : %s\n", strerror(errno));
        exit(1);
    }

    if (listen(S_waiting, Socket_wait_queue) == -1){
        fprintf(stderr, "can't listen : %s\n", strerror(errno));
        exit(1);
    }

/*
 * wait "shutdown" or "start_tran"
 */
    errno = 0;
    caddr_len = sizeof caddr;
    S_sock = accept(S_waiting, (struct sockaddr *)&caddr, &caddr_len);
    while (S_sock < 0 && errno == EINTR){
        errno = 0;
        S_sock = accept(S_waiting, (struct sockaddr *)&caddr, &caddr_len);
    }
    access_allow = FALSE;
    bzero(In_buf, BUF_LEN);
    if (S_sock >= 0){
        strncpy((char *)ipstr, (char *)inet_ntoa(caddr.sin_addr), 16);
        if (hosts_ctl(Daemon_name, STRING_UNKNOWN, ipstr, STRING_UNKNOWN)){
            ret = sock_read(S_sock, In_buf, BUF_LEN);
            access_allow = TRUE;
        }
    }

    while (!IsShutdown(In_buf)){
/*
 * wait terminated process
 */
        if (Sigchld_cnt > 0){
            errno = 0;
            ret = wait(&status);
            while (ret < 0 && errno == EINTR){
                errno = 0;
                ret = wait(&status);
            }
            if (ret > 0){
                Sigchld_cnt--;
            }
            while (ret > 0 && Sigchld_cnt > 0){
                errno = 0;
                ret = wait(&status);
                while (ret < 0 && errno == EINTR){
                    errno = 0;
                    ret = wait(&status);
                }
                if (ret > 0){
                    Sigchld_cnt--;
                }
            }
        }

        if (IsStart_tranm(In_buf)){
/*
 * multi processing (only get, getnext is allowed)
 */

            if (fork() == 0){

/* 
 * open database
 */
                DB_open();

                sprintf(Out_buf, "%-s\t%-s\n", "OK", "TRANSACTION START");
                sock_write(S_sock, Out_buf, strlen(Out_buf));

/*
 * wait db access command or "end_tran"
 */
                bzero(In_buf, BUF_LEN);
                ret = sock_read(S_sock, In_buf, BUF_LEN);

                while (ret > 0 &&
                       strncmp(In_buf, "end_tran", strlen("end_tran")) != 0 &&
                       strncmp(In_buf, "END_TRAN", strlen("END_TRAN")) != 0){

                    get_func_rec(In_buf);
                    for (i = 0; Tbl_rec[i].recname != NULL; i++){
                        if (strcmp(Tbl_rec[i].recname, RecName) == 0){
                            if (strcmp(FuncName, "get") == 0){
                                (*Tbl_rec[i].func_get)(In_buf);
                            }else if (strcmp(FuncName, "getnext") == 0){
                                (*Tbl_rec[i].func_getnext)(In_buf);
                            }else{
                                sprintf(Out_buf, "%-s\t%-s\n",
                                        "NG", "UNKNOWN FUNCTION");
                            }
                            break;
                        }
                    }
                    if (Tbl_rec[i].recname == NULL){
                        sprintf(Out_buf, "%-s\t%-s\n", "NG", "UNKNOWN RECORD");
                    }

                    sock_write(S_sock, Out_buf, strlen(Out_buf));

/*
 * wait db access command or "end_tran"
 */
                    bzero(In_buf, BUF_LEN);
                    ret = sock_read(S_sock, In_buf, BUF_LEN);
                }

/*
 * close database
 */
                DB_close();
                if (ret > 0){
                    sprintf(Out_buf, "%-s\t%-s\n", "OK", "TRANSACTION END");
                }else{
                    sprintf(Out_buf, "%-s\t%-s\n", "NG", "SOCKET READ ERROR");
                }
                sock_write(S_sock, Out_buf, strlen(Out_buf));

                close(S_sock);
                close(S_waiting);

                exit(0);
            }

        }else if (IsStart_tran(In_buf)){
/*
 * single processing (all functions are allowed)
 */

/*
 * wait termination of other ALL process
 */
            errno = 0;
            ret = wait(&status);
            while (ret > 0 || errno == EINTR){
                errno = 0;
                ret = wait(&status);
            }
            Sigchld_cnt = 0;

/*
 * set rollback journal switch
 */
            if (strncmp(In_buf, "start_tran_nj", strlen("start_tran_nj")) == 0 ||
                strncmp(In_buf, "START_TRAN_NJ", strlen("START_TRAN_NJ")) == 0){
                Rbj_sw = 0;
            }else{
                Rbj_sw = 1;
            }

            if (Debug > 0){
                printf("Rbj_sw=(%d)\n", Rbj_sw);
            }

/*
 * open journals
 */
            if (Rvj_sw == 1){
                if ((Fp_rvj = fopen(Rvj_name, "a")) == (FILE *)NULL){
                    fprintf(stderr, "recovery journal(%-s) can't open, crashed\n", Rvj_name);
                    exit(1);
                }
            }else{
                Fp_rvj = (FILE *)NULL;
            }

            if (Rbj_sw == 1){
                if ((Fp_rbj = fopen(Rbj_name, "w")) == (FILE *)NULL){
                    fprintf(stderr, "rollback journal(%-s) can't open, crashed\n", Rbj_name);
                    exit(1);
                }
            }else{
                Fp_rbj = (FILE *)NULL;
            }

/* 
 * open database
 */
            DB_open();

            sprintf(Out_buf, "%-s\t%-s\n", "OK", "TRANSACTION START");
            sock_write(S_sock, Out_buf, strlen(Out_buf));

/*
 * wait db access command or "end_tran"
 */
            bzero(In_buf, BUF_LEN);
            ret = sock_read(S_sock, In_buf, BUF_LEN);

            while (ret > 0 &&
                   strncmp(In_buf, "end_tran", strlen("end_tran")) != 0 &&
                   strncmp(In_buf, "END_TRAN", strlen("END_TRAN")) != 0 &&
                   strncmp(In_buf, "abort_tran", strlen("abort_tran")) != 0 &&
                   strncmp(In_buf, "ABORT_TRAN", strlen("ABORT_TRAN")) != 0){

                strncpy(In_buf_rvj, In_buf, sizeof In_buf_rvj);

                get_func_rec(In_buf);
                if (strcmp(FuncName, "ROLLBACK") == 0 ||
                    strcmp(FuncName, "rollback") == 0){
                    if (Rbj_sw == 1){
                        fclose(Fp_rbj);
                        if (rollback() == 0){
                            sprintf(Out_buf, "%-s\t%-s\n", "OK", "ROLLBACKED");
                            if ((Fp_rbj = fopen(Rbj_name, "w")) == (FILE *)NULL){
                                fprintf(stderr, "rollback journal(%-s) can't truncate, crashed\n", Rbj_name);
                                exit(1);
                            }
                        }else{
                            fprintf(stderr, "can't rollback, crashed\n");
                            exit(1);
                        }
                    }else{
                        sprintf(Out_buf, "%-s\t%-s\n", "NG", "NO ROLLBACK JOURNAL");
                    }
                }else if (strcmp(FuncName, "COMMIT") == 0 ||
                          strcmp(FuncName, "commit") == 0){
                    if (Rbj_sw == 1){
                        fclose(Fp_rbj);
                        if ((Fp_rbj = fopen(Rbj_name, "w")) == (FILE *)NULL){
                            fprintf(stderr, "rollback journal(%-s) can't truncate, crashed\n", Rbj_name);
                            exit(1);
                        }
                    }
                    if (Rvj_sw == 1){
                        fputs(In_buf_rvj, Fp_rvj);
                    }
                    sprintf(Out_buf, "%-s\t%-s\n", "OK", "COMMITED");
                }else{
                    for (i = 0; Tbl_rec[i].recname != NULL; i++){
                        if (strcmp(Tbl_rec[i].recname, RecName) == 0){
                            if (strcmp(FuncName, "GET") == 0 ||
                                strcmp(FuncName, "get") == 0){
                                (*Tbl_rec[i].func_get)(In_buf);
                            }else if (strcmp(FuncName, "PUT") == 0 ||
                                      strcmp(FuncName, "put") == 0){
                                (*Tbl_rec[i].func_put)(In_buf);
                            }else if (strcmp(FuncName, "UPDATE") == 0 ||
                                      strcmp(FuncName, "update") == 0){
                                (*Tbl_rec[i].func_update)(In_buf);
                            }else if (strcmp(FuncName, "DELETE") == 0 ||
                                      strcmp(FuncName, "delete") == 0){
                                (*Tbl_rec[i].func_delete)(In_buf);
                            }else if (strcmp(FuncName, "GETNEXT") == 0 ||
                                      strcmp(FuncName, "getnext") == 0){
                                (*Tbl_rec[i].func_getnext)(In_buf);
                            }else{
                                sprintf(Out_buf, "%-s\t%-s\n", 
                                        "NG", "UNKNOWN FUNCTION");
                            }
                            break;
                        }
                    }
                    if (Tbl_rec[i].recname == NULL){
                        sprintf(Out_buf, "%-s\t%-s\n", "NG", "UNKNOWN RECORD");
                    }
                }

                sock_write(S_sock, Out_buf, strlen(Out_buf));

                if (Safer_sw == 1){
                    if (Rvj_sw == 1){
                        fflush(Fp_rvj);
                        fsync(fileno(Fp_rvj));
                    }
                    if (Rbj_sw == 1){
                        fflush(Fp_rbj);
                        fsync(fileno(Fp_rbj));
                    }
                }

/*
 * wait db access command or "end_tran"
 */
                bzero(In_buf, BUF_LEN);
                ret = sock_read(S_sock, In_buf, BUF_LEN);
            }

            if (ret > 0){
                if (strncmp(In_buf, "end_tran", strlen("end_tran")) == 0 ||
                    strncmp(In_buf, "END_TRAN", strlen("END_TRAN")) == 0){
                    if (Rvj_sw == 1){
                        fputs(In_buf, Fp_rvj);
                    }
                }
            }
/*
 * close database
 */
            DB_close();
            if (Rvj_sw == 1){
                fclose(Fp_rvj);
            }
            if (Rbj_sw == 1){
                fclose(Fp_rbj);
            }

            if (ret > 0){
                if (strncmp(In_buf, "abort_tran", strlen("abort_tran")) == 0 ||
                    strncmp(In_buf, "ABORT_TRAN", strlen("ABORT_TRAN")) == 0){
                    if (rollback() == 0){
                        sprintf(Out_buf, "%-s\t%-s\n", "OK", "TRANSACTION ABORT, ROLLBACKED");
                        if (truncate(Rbj_name, 0) < 0){
                            fprintf(stderr, "rollback journal(%-s) can't truncate, crashed\n", Rbj_name);
                            exit(1);
                        }
                    }else{
                        fprintf(stderr, "can't rollback, crashed\n");
                        exit(1);
                    }
                }else{
                    sprintf(Out_buf, "%-s\t%-s\n", "OK", "TRANSACTION END");
                    if (truncate(Rbj_name, 0) < 0){
                        fprintf(stderr, "rollback journal(%-s) can't truncate, crashed\n", Rbj_name);
                        exit(1);
                    }
                }
            }else{
                if (rollback() == 0){
                    sprintf(Out_buf, "%-s\t%-s\n", "NG", "SOCKET READ ERROR, ROLLBACKED");
                    if (truncate(Rbj_name, 0) < 0){
                        fprintf(stderr, "rollback journal(%-s) can't truncate, crashed\n", Rbj_name);
                        exit(1);
                    }
                }else{
                    fprintf(stderr, "can't rollback, crashed\n");
                    exit(1);
                }
            }
            sock_write(S_sock, Out_buf, strlen(Out_buf));
        }else{
            if (!access_allow){
                sprintf(Out_buf, "%-s\t%-s(%-s)\n", "NG", "ACCESS DENIED", ipstr);
            }else if (!IsGranted){
                sprintf(Out_buf, "%-s\t%-s\n", "NG", "NOT GRANTED");
            }else{
                sprintf(Out_buf, "%-s\t%-s\n", "NG", "REQUIRE START_TRAN OR START_TRAN_NJ OR START_TRANM");
            }
            sock_write(S_sock, Out_buf, strlen(Out_buf));
        }

        close(S_sock);

/*
 * wait "shutdown" or "start_tran"
 */
        errno = 0;
        caddr_len = sizeof caddr;
        S_sock = accept(S_waiting, (struct sockaddr *)&caddr, &caddr_len);
        while (S_sock < 0 && errno == EINTR){
            errno = 0;
            S_sock = accept(S_waiting, (struct sockaddr *)&caddr, &caddr_len);
        }
        access_allow = 0;
        bzero(In_buf, BUF_LEN);
        if (S_sock >= 0){
            strncpy((char *)ipstr, (char *)inet_ntoa(caddr.sin_addr), 16);
            if (hosts_ctl(Daemon_name, STRING_UNKNOWN, ipstr, STRING_UNKNOWN)){
                ret = sock_read(S_sock, In_buf, BUF_LEN);
                access_allow = 1;
            }
        }
    }

    if (ret > 0){
        sprintf(Out_buf, "%-s\t%-s\n", "OK", "NORMAL SHUTDOWN");
    }else{
        sprintf(Out_buf, "%-s\t%-s\n", "NG", "CAN NOT READ SOCKET");
    }

/*
 * wait termination of other ALL process befor shutdown
 */
    if (Debug == 1){
        fprintf(stderr, "wait termination of children\n");
    }
    errno = 0;
    ret = wait(&status);
    while (ret > 0 || errno == EINTR){
        errno = 0;
        ret = wait(&status);
    }
    if (Debug == 1){
        fprintf(stderr, "all children terminated\n");
    }

    sock_write(S_sock, Out_buf, strlen(Out_buf));

    close(S_sock);
    close(S_waiting);
    return 0;
}

/*
 * signal trap
 */
void  SigTrap(sig)
    int  sig;
{
    int  status;

    signal(sig,  SIG_IGN);

    switch (sig){
    case SIGHUP:
        signal(sig,  SigTrap);
        break;
    case SIGCHLD:
        Sigchld_cnt++;
        signal(sig,  SigTrap);
        break;
    case SIGTERM:
        DB_close();
        close(S_sock);
        close(S_waiting);
        printf("SIGTERM catched and normal shutdown\n");
        exit(0);
        break;
    default:
        DB_close();
        close(S_sock);
        close(S_waiting);
        printf("signal(%d) catched and exit\n", sig);
        exit(0);
        break;
    }
}

/*
 * get db access function and record name
 */
int get_func_rec(buf)
    char *buf;
{
    char *p1, *p2;

    FuncName = RecName = NULL_STR;

    if ((p1 = strchr(buf, '\t')) == (char *)NULL){
        if ((p1 = strchr(buf, '\r')) == (char *)NULL){
            if ((p1 = strchr(buf, '\n')) == (char *)NULL){
                return -1;
            }
        }
        *p1 = '\0';
        FuncName = buf;
        return 0;
    }
    *p1 = '\0';
    FuncName = buf;

    p1++;
    if ((p2 = strchr(p1, '\t')) == (char *)NULL){
        if ((p2 = strchr(p1, '\r')) == (char *)NULL){
            if ((p2 = strchr(p1, '\n')) == (char *)NULL){
                return -1;
            }
        }
    }
    *p2 = '\0';

    if (Table_list[0] != '\0'){
        strncpy(Table_name, "\t", (sizeof Dbd_dir) - 1);
        strncat(Table_name, p1, (sizeof Table_name) - strlen(Table_name) - 1);
        strncat(Table_name, "\t", (sizeof Table_name) - strlen(Table_name) - 1);
        if (strstr(Table_list, Table_name) == (char *)NULL){
            return -1;
        }
    }

    RecName = p1;

    return 0;
}

/*
 * get key name and db access condition
 */
int get_key_cond(buf)
    char *buf;
{
    char *p1, *p2, *p3, *p4;

    KeyName = Condition = NULL_STR;

    p1 = buf + strlen(buf) + 1;
    p2 = p1 + strlen(p1) + 1;
    if ((p3 = strchr(p2, '\t')) == (char *)NULL){
        if ((p3 = strchr(p2, '\r')) == (char *)NULL){
            if ((p3 = strchr(p2, '\n')) == (char *)NULL){
                return -1;
            }
        }
        *p3 = '\0';
        KeyName = p2;
	return 0;
    }
    *p3 = '\0';
    KeyName = p2;

    p3++;
    if ((p4 = strchr(p3, '\t')) == (char *)NULL){
        if ((p4 = strchr(p3, '\r')) == (char *)NULL){
            if ((p4 = strchr(p3, '\n')) == (char *)NULL){
                return -1;
            }
        }
    }
    *p4 = '\0';
    Condition = p3;

    return 0;
}

/*
 * get key value
 */
int get_keyvalue(buf)
    char *buf;
{
    int  i;
    char *p;

    KeyValue = NULL_STR;

    for (i = 0; i < BUF_LEN; i++){
        if (*(buf + i) == '\t' || *(buf + i) == '\n' || *(buf + i) == '\r'){
            break;
        }
    }
    if (i >= BUF_LEN){
        return -1;
    }

    *(buf + i) = '\0';

    for (i--; i >= 0; i--){
        if (*(buf + i) == '\0'){
            KeyValue = buf + i + 1;
            break;
        }
    }
    if (i < 0){
        return -1;
    }
        
    if (*(KeyValue + strlen(KeyValue) - 1) == '\r'){
        *(KeyValue + strlen(KeyValue) - 1) = '\0';
    }
    return 0;
}

/*
 * get item name and item value
 */
int get_item_value(buf)
    char *buf;
{
    int  i;
    char *p;

    ItemName = ItemValue = NULL_STR;

    for (i = 0; i < BUF_LEN; i++){
        if (*(buf + i) == '\t' || *(buf + i) == '\n' || *(buf + i) == '\r'){
            break;
        }
    }
    if (i >= BUF_LEN){
        return -1;
    }

    *(buf + i) = '\0';

    for (i--; i >= 0; i--){
        if (*(buf + i) == '\0'){
            ItemName = buf + i + 1;
            break;
        }
    }
    if (i < 0){
        return -1;
    }

    if ((p = strchr(ItemName, '=')) == (char *)NULL){
        return -1;
    }
    *p = '\0';
    ItemValue = p + 1;
        
    if (*(ItemValue + strlen(ItemValue) - 1) == '\r'){
        *(ItemValue + strlen(ItemValue) - 1) = '\0';
    }
    return 0;
}

/*
 * open database
 */
int DB_open()
{
    char *p_env;

    /*
     * set dbd dir
     */
    d_dbdpath(Dbd_dir);

    /*
     * set data dir
     */
    d_dbfpath(Data_dir);

    /*
     * open database
     */
    if(d_open(DATABASE_NAME, "s") != S_OKAY){
        sprintf(Out_buf, "%-s\t%-s%d\n",
                "NG", "CAN NOT OPEN DATABASE db_status=", db_status);
        return -1;
    }
    return 0;
}

/*
 * close database
 */
int DB_close()
{
    /*
     * close database
     */
    d_close();
    return 0;
}

int  sock_read(s, buf, len)
    int    s;
    char * buf;
    int    len;
{
    int  ret, cnt = 0, rem_cnt = (len > BUF_LEN ? BUF_LEN : len);

    *buf = '\0';
    while (strchr(buf, '\n') == (char *)NULL &&
           strchr(buf, '\r') == (char *)NULL &&
           rem_cnt > 0){
        errno = 0;
        ret = read(s, Tmp_buf, sizeof Tmp_buf);
        while (ret < 0 && errno == EINTR){
            errno = 0;
            ret = read(s, Tmp_buf, sizeof Tmp_buf);
        }
        if (ret <= 0){
            *buf = '\0';
            return -1;
        }
        memcpy(buf + cnt, Tmp_buf, (ret > rem_cnt ? rem_cnt : ret));
        cnt += (ret > rem_cnt ? rem_cnt : ret);
        rem_cnt -= (ret > rem_cnt ? rem_cnt : ret);
        *(buf + (cnt >= BUF_LEN ? cnt - 1 : cnt)) = '\0';
    }

    return (cnt >= BUF_LEN ? cnt - 1 : cnt);
}

int  sock_write(s, buf, len)
    int  s;
    char *buf;
    int  len;
{
    int ret, cnt = 0, rem_cnt = (len > BUF_LEN ? BUF_LEN : len);

    while (rem_cnt > 0){
        if ((ret = write(s, buf + cnt, rem_cnt)) <= 0){
            return -1;
        }
        cnt += ret;
        rem_cnt -= ret;
    }
    return cnt;
}

int  init_file()
{
    FILE *fp;
    char buf[BUF_LEN];

    strncpy(Host_name, DEF_HOST, (sizeof Host_name) - 1);
    Socket_port = DEF_PORT;
    Socket_wait_queue = DEF_SOCKET_WAIT_QUEUE;
    strncpy(Dbd_dir, DEF_TYPHOON_DIR, (sizeof Dbd_dir) - 1);
    strncat(Dbd_dir, "/dbd", (sizeof Dbd_dir) - strlen(Dbd_dir) - 1);
    strncpy(Data_dir, DEF_TYPHOON_DIR, (sizeof Data_dir) - 1);
    strncat(Data_dir, "/data", (sizeof Data_dir) - strlen(Data_dir) - 1);
    strncpy(Rvj_name, Tyserv_rundir, (sizeof Rvj_name) - 1);
    strncat(Rvj_name, "/journal/rvj.dat", (sizeof Rvj_name) - strlen(Rvj_name) - 1);
    strncpy(Rbj_name, Tyserv_rundir, (sizeof Rbj_name) - 1);
    strncat(Rbj_name, "/journal/rbj.dat", (sizeof Rbj_name) - strlen(Rbj_name) - 1);
    strncpy(Tyserv_dir, DEF_TYSERV_DIR, (sizeof Tyserv_dir) - 1);
    strncpy(Rollback_script, DEF_TYSERV_DIR, (sizeof Rollback_script) - 1);
    strncat(Rollback_script, "/bin/tyrollback.sh", (sizeof Rollback_script) - strlen(Rollback_script) - 1);
    strncpy(Passwd_name, DEF_TYSERV_DIR, (sizeof Passwd_name) - 1);
    strncat(Passwd_name, "/etc/passwd", (sizeof Passwd_name) - strlen(Passwd_name) - 1);
    strncpy(Daemon_name, DEF_DAEMON_NAME, (sizeof Daemon_name) - 1);
    Table_list[0] = '\0';
    Rvj_sw = DEF_RVJ_SW;
    Safer_sw = DEF_SAFER_SW;
    Debug = DEF_DEBUG;

    strncpy(Conf_file, Tyserv_rundir, (sizeof Conf_file) - 1);
    strncat(Conf_file, "/conf/tyserv.conf", (sizeof Conf_file) - strlen(Conf_file) - 1);

    if ((fp = fopen(Conf_file, "r")) == (FILE *)NULL){
        fprintf(stderr, "can not open initfile(%-s), crashed\n", Conf_file);
        exit(1);
    }

    while (fgets(buf, sizeof buf, fp) != (char *)NULL){
        if (strchr(buf, '\n') != (char *)NULL){
            *(strchr(buf, '\n')) = '\0';
        }
        if (buf[0] == '#'){
            buf[0] = '\0';
        }
        if (strncmp(buf, "HOST_NAME=", strlen("HOST_NAME=")) == 0){
            strncpy(Host_name, buf + strlen("HOST_NAME="), (sizeof Host_name) - 1);
        }else if(strncmp(buf, "SOCKET_PORT=", strlen("SOCKET_PORT=")) == 0){
            Socket_port = atoi(buf + strlen("SOCKET_PORT="));
        }else if(strncmp(buf, "SOCKET_WAIT_QUEUE=", strlen("SOCKET_WAIT_QUEUE=")) == 0){
            Socket_wait_queue = atoi(buf + strlen("SOCKET_WAIT_QUEUE="));
        }else if(strncmp(buf, "TYPHOON_DIR=", strlen("TYPHOON_DIR=")) == 0){
            strncpy(Dbd_dir, buf + strlen("TYPHOON_DIR="), (sizeof Dbd_dir) - 1);
            strncat(Dbd_dir, "/dbd", (sizeof Dbd_dir) - strlen(Dbd_dir) - 1);
            strncpy(Data_dir, buf + strlen("TYPHOON_DIR="), (sizeof Data_dir) - 1);
            strncat(Data_dir, "/data", (sizeof Data_dir) - strlen(Data_dir) - 1);
        }else if(strncmp(buf, "TYSERV_DIR=", strlen("TYSERV_DIR=")) == 0){
            strncpy(Tyserv_dir, buf + strlen("TYSERV_DIR="), (sizeof Tyserv_dir) - 1);
            strncpy(Rollback_script, Tyserv_dir, (sizeof Rollback_script) - 1);
            strncat(Rollback_script, "/bin/tyrollback.sh", (sizeof Rollback_script) - strlen(Rollback_script) - 1);
            strncpy(Passwd_name, Tyserv_dir, (sizeof Passwd_name) - 1);
            strncat(Passwd_name, "/etc/passwd", (sizeof Passwd_name) - strlen(Passwd_name) - 1);
        }else if(strncmp(buf, "DAEMON_NAME=", strlen("DAEMON_NAME=")) == 0){
            strncpy(Daemon_name, buf + strlen("DAEMON_NAME="), (sizeof Daemon_name) - 1);
        }else if(strncmp(buf, "TABLE_LIST=", strlen("TABLE_LIST=")) == 0){
            strncat(Table_list, "\t", (sizeof Table_list) - 1);
            strncat(Table_list, buf + strlen("TABLE_LIST="), (sizeof Table_list) - strlen(Table_list) - 1);
        }else if(strncmp(buf, "RVJ_SW=", strlen("RVJ_SW=")) == 0){
            Rvj_sw = atoi(buf + strlen("RVJ_SW="));
        }else if(strncmp(buf, "SAFER_SW=", strlen("SAFER_SW=")) == 0){
            Safer_sw = atoi(buf + strlen("SAFER_SW="));
        }else if(strncmp(buf, "DEBUG=", strlen("DEBUG=")) == 0){
            Debug = atoi(buf + strlen("DEBUG="));
        }
    }

    if (Table_list[0] != '\0'){
        strncat(Table_list, "\t", (sizeof Table_list) - strlen(Table_list) - 1);
    }

    fclose(fp);

    if (Debug > 0){
        printf("Host_name=(%-s)\n", Host_name);
        printf("Socket_port=(%d)\n", Socket_port);
        printf("Socket_wait_queue=(%d)\n", Socket_wait_queue);
        printf("Dbd_dir=(%-s)\n", Dbd_dir);
        printf("Data_dir=(%-s)\n", Data_dir);
        printf("Rvj_name=(%-s)\n", Rvj_name);
        printf("Rbj_name=(%-s)\n", Rbj_name);
        printf("Rollback_script=(%-s)\n", Rollback_script);
        printf("Passwd_name=(%-s)\n", Passwd_name);
        printf("Daemon_name=(%-s)\n", Daemon_name);
        printf("Table_list=(%-s)\n", Table_list);
        printf("Rvj_sw=(%d)\n", Rvj_sw);
        printf("Safer_sw=(%d)\n", Safer_sw);
        printf("Debug=(%d)\n", Debug);
    }

    return 0;
}

int  rollback()
{
    int  status, pid, wpid;

#if 0
    fprintf(stderr, "rollback start\n");
#endif

    if ((pid = fork()) == 0){
        execl(Rollback_script, "tyrollback", "-d", Tyserv_rundir, (char *)NULL);
        fprintf(stderr, "can't exec %-s\n", Rollback_script);
        exit(1);
    }else{
        errno = 0;
        wpid = wait(&status);
        while (wpid < 0 && errno == EINTR){
            errno = 0;
            wpid = wait(&status);
        }
        if (wpid > 0){
            Sigchld_cnt--;
        }
        while (pid != wpid && wpid > 0){
            errno = 0;
            wpid = wait(&status);
            while (wpid < 0 && errno == EINTR){
                errno = 0;
                wpid = wait(&status);
            }
            if (wpid > 0){
                Sigchld_cnt--;
            }
        }
    }

    if (WIFEXITED(status) != 0){
        if (WEXITSTATUS(status) == 0){
#if 0
            fprintf(stderr, "rollback success\n");
#endif
            return 0;
        }else{
#if 0
            fprintf(stderr, "rollback failure\n");
#endif
            return -1;
        }
    }else{
#if 0
        fprintf(stderr, "rollback failure\n");
#endif
        return -1;
    }
}

int  IsShutdown(buf)
    char *buf;
{
    char *p1, *p2, *p3;
    char *command, *user, *password;
    int skip_sw;
    int i;

    IsGranted = FALSE;
    if ((Fp_passwd = fopen(Passwd_name, "r")) == (FILE *)NULL){
        fclose(Fp_passwd);
        return FALSE;
    }

    command = user = password = NULL_STR;

    if ((p1 = strchr(buf, '\t')) == (char *)NULL){
        fclose(Fp_passwd);
        return FALSE;
    }
    command = buf;
    if (strncmp(command, "shutdown", strlen("shutdown")) != 0 ||
        *(command + strlen("shutdown")) != '\t'){
        if (strncmp(command, "SHUTDOWN", strlen("SHUTDOWN")) != 0 ||
            *(command + strlen("SHUTDOWN")) != '\t'){
            IsGranted = TRUE;
            fclose(Fp_passwd);
            return FALSE;
        }
    }

    p1++;
    if ((p2 = strchr(p1, '\t')) == (char *)NULL){
        fclose(Fp_passwd);
        return FALSE;
    }
    user = p1;

    p2++;
    if ((p3 = strchr(p2, '\t')) == (char *)NULL){
        if ((p3 = strchr(p2, '\r')) == (char *)NULL){
            if ((p3 = strchr(p2, '\n')) == (char *)NULL){
                fclose(Fp_passwd);
                return FALSE;
            }
        }
    }
    password = p2;

    while ((char *)fgets(Pw_buf, sizeof Pw_buf, Fp_passwd) != (char *)NULL){
        skip_sw = 0;
        if ((p1 = strchr(Pw_buf, ':')) == (char *)NULL){
            skip_sw = 1;
        }
        if (skip_sw == 0){
            i = 0;
            while (*(user + i) != '\t' && *(Pw_buf + i) != ':'){
                if (*(user + i) != *(Pw_buf + i)){
                    skip_sw = 1;
                    break;
                }
                i++;
            }
        }
        if (skip_sw == 0){
            if (*(user + i) != '\t' || *(Pw_buf + i) != ':'){
                skip_sw = 1;
            }
        }

        if (skip_sw == 0){
            p1++;
            if ((p2 = strchr(p1, ':')) == (char *)NULL){
                skip_sw = 1;
            }
        }
        if (skip_sw == 0){
            i = 0;
            while (*(password + i) != '\t' && 
                   *(password + i) != '\n' &&
                   *(password + i) != '\r' &&
                   *(p1 + i) != ':'){
                if (*(password + i) != *(p1 + i)){
                    skip_sw = 1;
                    break;
                }
                i++;
            }
        }
        if (skip_sw == 0){
            if ((*(password + i) != '\t' &&
                 *(password + i) != '\n' &&
                 *(password + i) != '\r') || *(p1 + i) != ':'){
                skip_sw = 1;
            }
        }

        if (skip_sw == 0){
            p2++;
            if ((p3 = strchr(p2, ':')) == (char *)NULL){
                if ((p3 = strchr(p2, '\r')) == (char *)NULL){
                    if ((p3 = strchr(p2, '\n')) == (char *)NULL){
                        skip_sw = 1;
                    }
                }
            }
        }
        if (skip_sw == 0){
            if (strncmp(p2, "all", strlen("all")) != 0 &&
                strncmp(p2, "ALL", strlen("ALL")) != 0){
                skip_sw = 1;
            }
        }
        if (skip_sw == 0){
            break;
        }
    }

    fclose(Fp_passwd);
    if (skip_sw == 0){
        IsGranted = TRUE;
        return TRUE;
    }else{
        return FALSE;
    }
}

int  IsStart_tranm(buf)
    char *buf;
{
    char *p1, *p2, *p3;
    char *command, *user, *password;
    int skip_sw;
    int i;

    IsGranted = FALSE;
    if ((Fp_passwd = fopen(Passwd_name, "r")) == (FILE *)NULL){
        return FALSE;
    }

    command = user = password = NULL_STR;

    if ((p1 = strchr(buf, '\t')) == (char *)NULL){
        fclose(Fp_passwd);
        return FALSE;
    }
    command = buf;
    if (strncmp(command, "start_tranm", strlen("start_tranm")) != 0 ||
        *(command + strlen("start_tranm")) != '\t'){
        if (strncmp(command, "START_TRANM", strlen("START_TRANM")) != 0 ||
            *(command + strlen("START_TRANM")) != '\t'){
            IsGranted = TRUE;
            fclose(Fp_passwd);
            return FALSE;
        }
    }

    p1++;
    if ((p2 = strchr(p1, '\t')) == (char *)NULL){
        fclose(Fp_passwd);
        return FALSE;
    }
    user = p1;

    p2++;
    if ((p3 = strchr(p2, '\t')) == (char *)NULL){
        if ((p3 = strchr(p2, '\r')) == (char *)NULL){
            if ((p3 = strchr(p2, '\n')) == (char *)NULL){
                fclose(Fp_passwd);
                return FALSE;
            }
        }
    }
    password = p2;

    while ((char *)fgets(Pw_buf, sizeof Pw_buf, Fp_passwd) != (char *)NULL){
        skip_sw = 0;
        if ((p1 = strchr(Pw_buf, ':')) == (char *)NULL){
            skip_sw = 1;
        }
        if (skip_sw == 0){
            i = 0;
            while (*(user + i) != '\t' && *(Pw_buf + i) != ':'){
                if (*(user + i) != *(Pw_buf + i)){
                    skip_sw = 1;
                    break;
                }
                i++;
            }
        }
        if (skip_sw == 0){
            if (*(user + i) != '\t' || *(Pw_buf + i) != ':'){
                skip_sw = 1;
            }
        }

        if (skip_sw == 0){
            p1++;
            if ((p2 = strchr(p1, ':')) == (char *)NULL){
                skip_sw = 1;
            }
        }
        if (skip_sw == 0){
            i = 0;
            while (*(password + i) != '\t' && 
                   *(password + i) != '\n' &&
                   *(password + i) != '\r' &&
                   *(p1 + i) != ':'){
                if (*(password + i) != *(p1 + i)){
                    skip_sw = 1;
                    break;
                }
                i++;
            }
        }
        if (skip_sw == 0){
            if ((*(password + i) != '\t' &&
                 *(password + i) != '\n' &&
                 *(password + i) != '\r') || *(p1 + i) != ':'){
                skip_sw = 1;
            }
        }

        if (skip_sw == 0){
            p2++;
            if ((p3 = strchr(p2, ':')) == (char *)NULL){
                if ((p3 = strchr(p2, '\r')) == (char *)NULL){
                    if ((p3 = strchr(p2, '\n')) == (char *)NULL){
                        skip_sw = 1;
                    }
                }
            }
        }
        if (skip_sw == 0){
            if (strncmp(p2, "all", strlen("all")) != 0 &&
                strncmp(p2, "ALL", strlen("ALL")) != 0 &&
                strncmp(p2, "full", strlen("full")) != 0 &&
                strncmp(p2, "FULL", strlen("FULL")) != 0 &&
                strncmp(p2, "get", strlen("get")) != 0 &&
                strncmp(p2, "GET", strlen("GET")) != 0){
                skip_sw = 1;
            }
        }
        if (skip_sw == 0){
            break;
        }
    }

    fclose(Fp_passwd);
    if (skip_sw == 0){
        IsGranted = TRUE;
        return TRUE;
    }else{
        return FALSE;
    }
}

int  IsStart_tran(buf)
    char *buf;
{
    char *p1, *p2, *p3;
    char *command, *user, *password;
    int skip_sw;
    int i;

    IsGranted = FALSE;
    if ((Fp_passwd = fopen(Passwd_name, "r")) == (FILE *)NULL){
        fclose(Fp_passwd);
        return FALSE;
    }

    command = user = password = NULL_STR;

    if ((p1 = strchr(buf, '\t')) == (char *)NULL){
        fclose(Fp_passwd);
        return FALSE;
    }
    command = buf;
    if (strncmp(command, "start_tran", strlen("start_tran")) != 0 ||
        *(command + strlen("start_tran")) != '\t'){
        if (strncmp(command, "START_TRAN", strlen("START_TRAN")) != 0 ||
            *(command + strlen("START_TRAN")) != '\t'){
            if (strncmp(command, "start_tran_nj", strlen("start_tran_nj")) != 0 ||
                *(command + strlen("start_tran_nj")) != '\t'){
                if (strncmp(command, "START_TRAN_NJ", strlen("START_TRAN_NJ")) != 0 ||
                    *(command + strlen("START_TRAN_NJ")) != '\t'){
                    IsGranted = TRUE;
                    fclose(Fp_passwd);
                    return FALSE;
                }
            }
        }
    }

    p1++;
    if ((p2 = strchr(p1, '\t')) == (char *)NULL){
        fclose(Fp_passwd);
        return FALSE;
    }
    user = p1;

    p2++;
    if ((p3 = strchr(p2, '\t')) == (char *)NULL){
        if ((p3 = strchr(p2, '\r')) == (char *)NULL){
            if ((p3 = strchr(p2, '\n')) == (char *)NULL){
                fclose(Fp_passwd);
                return FALSE;
            }
        }
    }
    password = p2;

    while ((char *)fgets(Pw_buf, sizeof Pw_buf, Fp_passwd) != (char *)NULL){
        skip_sw = 0;
        if ((p1 = strchr(Pw_buf, ':')) == (char *)NULL){
            skip_sw = 1;
        }
        if (skip_sw == 0){
            i = 0;
            while (*(user + i) != '\t' && *(Pw_buf + i) != ':'){
                if (*(user + i) != *(Pw_buf + i)){
                    skip_sw = 1;
                    break;
                }
                i++;
            }
        }
        if (skip_sw == 0){
            if (*(user + i) != '\t' || *(Pw_buf + i) != ':'){
                skip_sw = 1;
            }
        }

        if (skip_sw == 0){
            p1++;
            if ((p2 = strchr(p1, ':')) == (char *)NULL){
                skip_sw = 1;
            }
        }
        if (skip_sw == 0){
            i = 0;
            while (*(password + i) != '\t' && 
                   *(password + i) != '\n' &&
                   *(password + i) != '\r' &&
                   *(p1 + i) != ':'){
                if (*(password + i) != *(p1 + i)){
                    skip_sw = 1;
                    break;
                }
                i++;
            }
        }
        if (skip_sw == 0){
            if ((*(password + i) != '\t' &&
                 *(password + i) != '\n' &&
                 *(password + i) != '\r') || *(p1 + i) != ':'){
                skip_sw = 1;
            }
        }

        if (skip_sw == 0){
            p2++;
            if ((p3 = strchr(p2, ':')) == (char *)NULL){
                if ((p3 = strchr(p2, '\r')) == (char *)NULL){
                    if ((p3 = strchr(p2, '\n')) == (char *)NULL){
                        skip_sw = 1;
                    }
                }
            }
        }
        if (skip_sw == 0){
            if (strncmp(p2, "all", strlen("all")) != 0 &&
                strncmp(p2, "ALL", strlen("ALL")) != 0 &&
                strncmp(p2, "full", strlen("full")) != 0 &&
                strncmp(p2, "FULL", strlen("FULL")) != 0){
                skip_sw = 1;
            }
        }
        if (skip_sw == 0){
            break;
        }
    }

    fclose(Fp_passwd);
    if (skip_sw == 0){
        IsGranted = TRUE;
        return TRUE;
    }else{
        return FALSE;
    }
}
