TYSERV_DIR	= /home/tyserv/tyserv

DEFINES		=
CFLAGS		= -O $(DEFINES) # -v
OBJS		= tytran.o
CC		= gcc
SHELL		= /bin/sh
LDFLAGS		=
LIBS		=
INSTALL_DIR	= $(TYSERV_DIR)/bin

all:	tytran tytran.sh

tytran:	$(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJS) $(LIBS)

install:
	cp tytran $(INSTALL_DIR)/tytran
	cp tytran.sh $(INSTALL_DIR)/tytran.sh
	chmod 755 $(INSTALL_DIR)/tytran.sh
