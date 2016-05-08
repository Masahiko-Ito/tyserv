/*
 * __MESSAGE__
 *
 * tyhpoon database search program by M.Ito
 *
 * Usage : tysearch TABLE   START   RECCOUNT KEY     KEYVALUE ...
 *                  argv[1] argv[2] argv[3]  argv[4] argv[5]
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
#define  DATABASE_NAME "typhoondb"
#include "typhoondb.h"

#define DEF_DBD_DIR  "/home/tyserv/typhoon/dbd"
#define DEF_DATA_DIR "/home/tyserv/typhoon/data"

#define BUF_LEN (1024 * 16)
#define DIR_LEN (256)

int  Rvj_sw;
int  Rbj_sw;

int  Fd_rvj;
int  Fd_rbj;

char Tmp_buf[BUF_LEN];
char In_buf[BUF_LEN];
char In_buf_rvj[BUF_LEN];
char Out_buf[BUF_LEN];
char Out_buf_rbj[BUF_LEN];

char Dbd_dir[DIR_LEN];
char Data_dir[DIR_LEN];

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
    int  i, j, ret;

    if (argc == 2){
        if (strcmp(argv[1], "-h") == 0 ||
            strcmp(argv[1], "--help") == 0){
            printf("usage : %-s table start_count rec_count key_name key_value ... \n", argv[0]);
            printf("environment value : TYPHOON_DIR\n");
            exit(0);
        }
    }

    bzero(In_buf, BUF_LEN);
    sprintf(In_buf, "get\t%-s\t%-s\tge", argv[1], argv[4]);
    for (i = 5; i < (argc - 1); i++){
        sprintf(In_buf, "%-s\t%-s", In_buf, argv[i]);
    }
    sprintf(In_buf, "%-s\t%-s\n", In_buf, argv[argc - 1]);

/* 
 * open database
 */
    if ((ret = DB_open()) < 0){
        printf(Out_buf);
    }

    get_func_rec(In_buf);
    for (i = 0; Tbl_rec[i].recname != NULL; i++){
        if (strcmp(Tbl_rec[i].recname, RecName) == 0){
            (*Tbl_rec[i].func_get)(In_buf);
            for (j = 0; j < (atoi(argv[2]) + atoi(argv[3]) - 1) &&
                        strncmp(Out_buf, "NG", 2) != 0; j++){
                if (j >= (atoi(argv[2]) - 1)){
                    printf(Out_buf);
                }

                sprintf(In_buf, "getnext\t%-s\t%-s\n", argv[1], argv[4]);
                get_func_rec(In_buf);
                (*Tbl_rec[i].func_getnext)(In_buf);
            }
            break;
        }
    }
    if (Tbl_rec[i].recname == NULL){
        sprintf(Out_buf, "%-s\t%-s\n", "NG", "UNKNOWN RECORD");
        printf(Out_buf);
    }

/*
 * close database
 */
    DB_close();

    exit(0);
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
    if ((p_env = (char *)getenv("TYPHOON_DIR")) == NULL){
        strncpy(Dbd_dir, DEF_DBD_DIR, (sizeof Dbd_dir) - 1);
    }else{
        strncpy(Dbd_dir, p_env, (sizeof Dbd_dir) - 1);
        strncat(Dbd_dir, "/dbd", (sizeof Dbd_dir) - strlen(Dbd_dir) - 1);
    }
    d_dbdpath(Dbd_dir);

    /*
     * set data dir
     */
    if ((p_env = (char *)getenv("TYPHOON_DIR")) == NULL){
        strncpy(Data_dir, DEF_DATA_DIR, (sizeof Data_dir) - 1);
    }else{
        strncpy(Data_dir, p_env, (sizeof Data_dir) - 1);
        strncat(Data_dir, "/data", (sizeof Data_dir) - strlen(Data_dir) - 1);
    }
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
