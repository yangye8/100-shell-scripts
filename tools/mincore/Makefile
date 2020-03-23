.PHONY : clean

all : mincore

CFLAGS += -Wall -Werror -g

%.o : %.c
	$(CC) $(CFLAGS) $(LDFLAGS) -c $< $@

clean:
	rm -rf *.o mincore
