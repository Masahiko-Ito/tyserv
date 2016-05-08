/*
 * __MESSAGE__
 *
 * tyhpoon database recovery program by M.Ito
 * Ver. 1.0    2002.07.01
 */
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <string.h>
#include <errno.h>
#include <signal.h>

#include <ctype.h>
#include <typhoon.h>

/* DataBase definition */
#define  DATABASE_NAME "__DB__"
#include "__DB__.h"

#define FD_STDIN (0)
#define BUF_LEN (1024 * 16)
#define PATH_LEN (256)

#define DEF_TYPHOON_DIR  "/usr/local/typhoon"
#define DEF_TYSERV_DIR  "/usr/local/tyserv"
#define DEF_RBJ_SW (0)
#define DEF_SAFER_SW (1)
#define DEF_DEBUG (0)

char Dbd_dir[PATH_LEN];
char Data_dir[PATH_LEN];
char Rvj_name[PATH_LEN];
char Rbj_name[PATH_LEN];
int  Rvj_sw;
int  Rbj_sw;
int  Safer_sw;
int  Debug;

FILE *Fp_rvj;
FILE *Fp_rbj;

char Tmp_buf[BUF_LEN];
char In_buf[BUF_LEN];
char In_buf_rvj[BUF_LEN];
char Out_buf[BUF_LEN];
char Out_buf_rbj[BUF_LEN];

int  Ok_sw = 1;

void  SigTrap();

int  init_file();

int  get_func_rec();
char *FuncName;
char *RecName;

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

    int  i, ret, fd, status;

    if (argc < 2){
        fprintf(stderr, "usage : %-s RVJ_SW\n", argv[0]);
        exit(1);
    }

/*
 * set signal trap
 */
    signal(SIGHUP, SIG_IGN);  /* hangup */
    signal(SIGINT, SIG_IGN);  /* interrupt */
    signal(SIGQUIT, SIG_IGN); /* quit */
    signal(SIGTERM, SigTrap); /* software termination signal from kill */

/*
 * set from initialze file
 */
    init_file();

    Rvj_sw = atoi(argv[1]);
    Rbj_sw = DEF_RBJ_SW;

/*
 * open journals
 */
    if (Rvj_sw == 1){
        if ((Fp_rvj = fopen(Rvj_name, "a")) == (FILE *)NULL){
            fprintf(stderr, "recovery journal(%-s) can't open\n", Rvj_name);
            exit(1);
        }
    }else{
        Fp_rvj = (FILE *)NULL;
    }

    Fp_rbj = (FILE *)NULL;

/*
 * data base open
 */
    if (DB_open() < 0){
        fprintf(stderr, Out_buf);
        exit(1);
    }

/*
 * wait recovery command
 */
    while (fgets(In_buf, sizeof In_buf, stdin) != (char *)NULL){

        strncpy(In_buf_rvj, In_buf, sizeof In_buf_rvj);

        get_func_rec(In_buf);
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

        if (strncmp(Out_buf, "NG", strlen("NG")) == 0){
            fprintf(stderr, Out_buf);
            Ok_sw = 0;
        }else{
            if (Debug == 1){
                fprintf(stderr, Out_buf);
            }
        }
    }

    if (Rvj_sw == 1){
        fclose(Fp_rvj);
    }
    DB_close();
    if (Ok_sw == 1){
        exit(0);
    }else{
        exit(1);
    }
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
    case SIGTERM:
    default:
        DB_close();
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

    FuncName = RecName = "";

    if ((p1 = strchr(buf, '\t')) == (char *)NULL){
        return -1;
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

    KeyName = Condition = "";

    p1 = buf + strlen(buf) + 1;
    p2 = p1 + strlen(p1) + 1;
    if ((p3 = strchr(p2, '\t')) == (char *)NULL){
        if ((p3 = strchr(p2, '\r')) == (char *)NULL){
            if ((p3 = strchr(p2, '\n')) == (char *)NULL){
                return -1;
            }
        }
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

    KeyValue = "";

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

    ItemName = ItemValue = "";

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
     *  open database
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

int  init_file()
{
    FILE *fp;
    char buf[BUF_LEN];

    strncpy(Dbd_dir, DEF_TYPHOON_DIR, (sizeof Dbd_dir) - 1);
    strncat(Dbd_dir, "/dbd", (sizeof Dbd_dir) - strlen(Dbd_dir) - 1);
    strncpy(Data_dir, DEF_TYPHOON_DIR, (sizeof Data_dir) - 1);
    strncat(Data_dir, "/data", (sizeof Data_dir) - strlen(Data_dir) - 1);
    strncpy(Rvj_name, DEF_TYSERV_DIR, (sizeof Rvj_name) - 1);
    strncat(Rvj_name, "/journal/rvj.dat", (sizeof Rvj_name) - strlen(Rvj_name) - 1);
    strncpy(Rbj_name, DEF_TYSERV_DIR, (sizeof Rbj_name) - 1);
    strncat(Rbj_name, "/journal/rbj.dat", (sizeof Rbj_name) - strlen(Rbj_name) - 1);
    Safer_sw = DEF_SAFER_SW;
    Debug = DEF_DEBUG;

    if ((fp = fopen("__INITFILE__", "r")) == (FILE *)NULL){
        fprintf(stderr, "can not open initfile(%-s)\n", "__INITFILE__");
        exit(1);
    }

    while (fgets(buf, sizeof buf, fp) != (char *)NULL){
        if (strchr(buf, '\n') != (char *)NULL){
            *(strchr(buf, '\n')) = '\0';
        }
        if (buf[0] == '#'){
            buf[0] = '\0';
        }
        if(strncmp(buf, "TYPHOON_DIR=", strlen("TYPHOON_DIR=")) == 0){
            strncpy(Dbd_dir, buf + strlen("TYPHOON_DIR="), (sizeof Dbd_dir) - 1);
            strncat(Dbd_dir, "/dbd", (sizeof Dbd_dir) - strlen(Dbd_dir) - 1);
            strncpy(Data_dir, buf + strlen("TYPHOON_DIR="), (sizeof Data_dir) - 1);
            strncat(Data_dir, "/data", (sizeof Data_dir) - strlen(Data_dir) - 1);
        }else if(strncmp(buf, "TYSERV_DIR=", strlen("TYSERV_DIR=")) == 0){
            strncpy(Rvj_name, buf + strlen("TYSERV_DIR="), (sizeof Rvj_name) - 1);
            strncat(Rvj_name, "/journal/rvj.dat", (sizeof Rvj_name) - strlen(Rvj_name) - 1);
            strncpy(Rbj_name, buf + strlen("TYPHOON_DIR="), (sizeof Rbj_name) - 1);
            strncat(Rbj_name, "/journal/rbj.dat", (sizeof Rbj_name) - strlen(Rbj_name) - 1);
        }else if(strncmp(buf, "SAFER_SW=", strlen("SAFER_SW=")) == 0){
            Safer_sw = atoi(buf + strlen("SAFER_SW="));
        }else if(strncmp(buf, "DEBUG=", strlen("DEBUG=")) == 0){
            Debug = atoi(buf + strlen("DEBUG="));
        }
    }

    fclose(fp);

    if (Debug > 0){
        printf("Dbd_dir=(%-s)\n", Dbd_dir);
        printf("Data_dir=(%-s)\n", Data_dir);
        printf("Rvj_name=(%-s)\n", Rvj_name);
        printf("Rbj_name=(%-s)\n", Rbj_name);
        printf("Safer_sw=(%d)\n", Safer_sw);
        printf("Debug=(%d)\n", Debug);
    }

    return 0;
}

