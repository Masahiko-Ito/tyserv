TYPHOON_DIR	= /home/tyserv/typhoon
TYSERV_DIR	= /home/tyserv/tyserv

DEFINES		= -I/usr/local/include -I$(TYPHOON_DIR)/include
CFLAGS		= -O $(DEFINES) # -v
SRV_OBJ		= tyserv.o
RCV_OBJ		= tyrecover.o
COM_OBJ		= tysearch.o
OBJS		= tyserv_smp1.o \
		  tyserv_smp2.o
#		  tyserv_smp3.o
CC		= gcc
SHELL		= /bin/sh
LDFLAGS		= -L/usr/local/lib

# for FreeBSD
#LIBS		= -ltyphoon -lcompat -lwrap
# for Linux
LIBS		= -ltyphoon -lwrap
INSTALL_DIR	= $(TYSERV_DIR)/bin

all:	tyserv tyrecover tysearch

tyserv:	$(SRV_OBJ) $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(SRV_OBJ) $(OBJS) $(LIBS)

tyrecover:	$(RCV_OBJ) $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(RCV_OBJ) $(OBJS) $(LIBS)

tysearch:    $(COM_OBJ) $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(COM_OBJ) $(OBJS) $(LIBS)

install:
	cp tyserv $(INSTALL_DIR)/tyserv
	chmod 4700 $(INSTALL_DIR)/tyserv
	cp tyrecover $(INSTALL_DIR)/tyrecover
	chmod 4700 $(INSTALL_DIR)/tyrecover
	cp tysearch $(INSTALL_DIR)/tysearch
	chmod 4700 $(INSTALL_DIR)/tysearch

src:
	$(INSTALL_DIR)/mktyserv all
