#include <stdio.h>
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <string.h>

/*
 * ソケットオープン
 */
sock_open(host, port, fd_sock)
     char           *host;	/* in  : must be NULL terminated */
     char           *port;	/* in  : must be NULL terminated */
     char           *fd_sock;	/* out : will be NULL terminated */
{
    struct sockaddr_in sv_addr;
    struct hostent *sv_ip;
    int             fd;
    int             ret;

    /*
     * コネクション型ソケットの作成 (socket) 
     */
    fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) {
	fd_sock[0] = '\0';
	return -1;
    }

    /*
     * サーバのＩＰアドレスを取得 
     */
    sv_ip = gethostbyname(host);
    if (sv_ip == NULL) {
	fd_sock[0] = '\0';
	return -1;
    }

    /*
     * ソケットの接続要求 (connect) 
     */
    bzero((char *) &sv_addr, sizeof(sv_addr));
    sv_addr.sin_family = AF_INET;
    sv_addr.sin_port = htons(atoi(port));
    memcpy((char *) &sv_addr.sin_addr, (char *) sv_ip->h_addr,
	   sv_ip->h_length);
    ret = connect(fd, &sv_addr, sizeof(sv_addr));
    if (ret < 0) {
	close(fd);
	fd_sock[0] = '\0';
	return -1;
    }

    sprintf(fd_sock, "%-5d", fd);
    return 0;
}

/*
 * ソケットデータ送受信
 */
sock_send_recv(fd_sock, send_data, recv_data)
     char           *fd_sock;	/* in  : must be NULL terminated */
     char           *send_data;	/* in  : must be NULL terminated */
     char           *recv_data;	/* out : will be NULL terminated */
{
    int             i;
    int             fd;
    int             ret;

    fd = atoi(fd_sock);

    i = 0;
    ret = write(fd, send_data + i, strlen(send_data + i));
    while (ret >= 0 && ret < strlen(send_data + i)){
    	i += ret;
    	ret = write(fd, send_data + i, strlen(send_data + i));
    }
    write(fd, "\n", 1);

    i = 0;
    ret = read(fd, recv_data + i, 1);
    while (ret > 0 && *(recv_data + i) != '\n') {
	i++;
        ret = read(fd, recv_data + i, 1);
    }
    recv_data[i] = '\0';
    return 0;
}

/*
 * ソケットクローズ
 */
sock_close(fd_sock)
     char           *fd_sock;	/* in  : must be NULL terminated */
{
    int             fd;
    int             ret;

    fd = atoi(fd_sock);
    /*
     * ソケットの開放 
     */
    shutdown(fd, 2);
    close(fd);
    return 0;
}

/*
 * ステータス取得
 */
get_status(recv_data, sts1, sts2)
     char           *recv_data;	/* in  : must be NULL terminated */
     char           *sts1;	/* out : will NOT be NULL terminated */
     char           *sts2;	/* out : will NOT be NULL terminated */
{
    char	*ptr, *ptr1, *ptr2;
    int		i;

    ptr1 = recv_data;
    ptr2 = strchr(recv_data, '\t');
    i = 0;
    for (ptr = ptr1; ptr < ptr2; ptr++){
    	sts1[i] = *ptr;
    	i++;
    }

    ptr1 = ptr2 + 1;
    if ((ptr2 = strchr(ptr1, '\t')) == (char *)NULL){
        if ((ptr2 = strchr(ptr1, '\r')) == (char *)NULL){
            if ((ptr2 = strchr(ptr1, '\n')) == (char *)NULL){
                ptr2 = strchr(ptr1, '\0');
	    }
    	}
    }

    i = 0;
    for (ptr = ptr1; ptr < ptr2; ptr++){
    	sts2[i] = *ptr;
    	i++;
    }

    return 0;
}

/*
 * 項目内容取得
 */
get_value(recv_data, name, value)
     char           *recv_data;	/* in  : must be NULL terminated */
     char           *name;	/* in  : must be NULL terminated */
     char           *value;	/* out : will NOT be NULL terminated */
{
    char	*ptr, *ptr1, *ptr2, *ptr3, namebuf[256];
    int		i;

    strncpy(namebuf, name, (sizeof namebuf) - 1);
    strncat(namebuf, "=", (sizeof namebuf) - strlen(namebuf) - 1);
    namebuf[(sizeof namebuf) - 1] = '\0';
    ptr1 = strstr(recv_data, namebuf);

    if (ptr1 != (char *)NULL){
    	ptr2 = strchr(ptr1, '=');
    	ptr2++;
    	if ((ptr3 = strchr(ptr2, '\t')) == (char *)NULL){
            if ((ptr3 = strchr(ptr2, '\r')) == (char *)NULL){
            	if ((ptr3 = strchr(ptr2, '\n')) == (char *)NULL){
                    ptr3 = strchr(ptr2, '\0');
	    	}
    	    }
    	}

    	i = 0;
    	for (ptr = ptr2; ptr < ptr3; ptr++){
    	    value[i] = *ptr;
    	    i++;
    	}
    }

    return 0;
}
