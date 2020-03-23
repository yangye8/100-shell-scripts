# Makefile for hdparm
CC ?= gcc
STRIP ?= strip

CFLAGS := -O2 -W -Wall -Wbad-function-cast -Wcast-align -Wpointer-arith -Wcast-qual -Wshadow -Wstrict-prototypes -Wmissing-prototypes -Wmissing-declarations -fkeep-inline-functions -Wwrite-strings -Waggregate-return -Wnested-externs -Wtrigraphs $(CFLAGS)

LDFLAGS = -s
#LDFLAGS = -s -static

OBJS = hdparm.o 

all:
	$(MAKE) -j4 hdparm

hdparm: $(OBJS)
	$(CC) $(LDFLAGS) -o hdparm $(OBJS)
	$(STRIP) hdparm

clean:
	-rm -f hdparm $(OBJS) core 2>/dev/null

