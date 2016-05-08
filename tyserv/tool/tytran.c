#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <string.h>
#include <errno.h>

#define BUF_LEN (1024 * 16)
#define PATH_LEN (256)

char Host_name[PATH_LEN];
unsigned short Socket_port;
int  Ng_exit;
int  Verbose;

int  S_sock;
char Tmp_buf[BUF_LEN];
char Buf1[BUF_LEN];
char Buf2[BUF_LEN];

int  sock_read();
int  sock_write();

int main(argc, argv)
    int  argc;
    char *argv[];
{
    struct hostent *server_ent;
    struct sockaddr_in server_in;

    int  ret, exit_flg;

/*
 * set from initialze file
 */
    if (argc < 5){
        fprintf(stderr, "usage : %-s SERVER PORT NGEXIT VERBOSE\n", argv[0]);
        exit(1);
    }

    Host_name[(sizeof Host_name) - 1] = '\0';
    strncpy(Host_name, argv[1], (sizeof Host_name) - 1);
    Socket_port = atoi(argv[2]);
    Ng_exit = atoi(argv[3]);
    Verbose = atoi(argv[4]);

/*
 * make socket
 */
    if ((server_ent = gethostbyname(Host_name)) == (struct hostent *)NULL){
        fprintf(stderr, "can't gethostbyname(%-s)\n", Host_name);
        exit(1);
    }
    bzero((char *)&server_in, sizeof server_in);
    server_in.sin_family = AF_INET;
    server_in.sin_port = htons(Socket_port);
    bcopy(server_ent->h_addr, (char *)&server_in.sin_addr, server_ent->h_length);

/*
 * ready socket
 */
    if ((S_sock = socket(AF_INET, SOCK_STREAM, 0)) == -1){
        fprintf(stderr, "can't create socket : %s\n", strerror(errno));
        exit(1);
    }

    if (connect(S_sock, &server_in, sizeof (server_in)) == -1){
        fprintf(stderr, "can't connect : %s\n", strerror(errno));
        exit(1);
    }

    exit_flg = 0;
    while (exit_flg == 0 && fgets(Buf1, sizeof Buf1, stdin) != (char *)NULL){

        Buf2[(sizeof Buf2) - 1] = '\0';
        strncpy(Buf2, Buf1, (sizeof Buf2) - 1);

        ret = sock_write(S_sock, Buf1, strlen(Buf1));
        if (ret < 0){
            close(S_sock);
            if ((S_sock = socket(AF_INET, SOCK_STREAM, 0)) == -1){
                fprintf(stderr, "can't recreate socket for write: %s\n", strerror(errno));
                exit(1);
            }
        
            if (connect(S_sock, &server_in, sizeof (server_in)) == -1){
                fprintf(stderr, "can't reconnect for write: %s\n", strerror(errno));
                exit(1);
            }

            Buf1[(sizeof Buf1) - 1] = '\0';
            strncpy(Buf1, Buf2, (sizeof Buf1) - 1);

            ret = sock_write(S_sock, Buf1, strlen(Buf1));
            if (ret < 0){
                fprintf(stderr, "can't write to socket : %s\n", strerror(errno));
                exit(1);
            }
        }

        ret = sock_read(S_sock, Buf1, sizeof Buf1);
        if (ret < 0){
            close(S_sock);
            if ((S_sock = socket(AF_INET, SOCK_STREAM, 0)) == -1){
                fprintf(stderr, "can't recreate socket for read: %s\n", strerror(errno));
                exit(1);
            }
        
            if (connect(S_sock, &server_in, sizeof (server_in)) == -1){
                fprintf(stderr, "can't reconnect for read: %s\n", strerror(errno));
                exit(1);
            }

            Buf1[(sizeof Buf1) - 1] = '\0';
            strncpy(Buf1, Buf2, (sizeof Buf1) - 1);

            ret = sock_write(S_sock, Buf1, strlen(Buf1));
            if (ret < 0){
                fprintf(stderr, "can't write to socket : %s\n", strerror(errno));
                exit(1);
            }

            ret = sock_read(S_sock, Buf1, sizeof Buf1);
            if (ret < 0){
                fprintf(stderr, "can't read from socket : %s\n", strerror(errno));
                exit(1);
            }
        }

        if (Verbose == 1){
            fprintf(stdout, Buf1);
            fflush(stdout);
        }

        if (Ng_exit == 1){
            if (strncmp(Buf1, "NG", strlen("NG")) == 0){
                exit_flg = 1;
            }
        }
    }

    close(S_sock);

    if (exit_flg == 1){
        return 1;
    }else{
        return 0;
    }
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
