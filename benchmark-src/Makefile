TARGETS = bench-malloc-thread bench-malloc-thread-lab
LIBS = -lpthread
SHAREDLIBS = ../laballoc-install/libimproved
INCLUDES1 = ../
INCLUDES2 = ../laballoc-install
CC = gcc
CFLAGS = -g -Wall -O2 -std=gnu99

.PHONY: default all clean

default: $(TARGETS)

all: default

OBJECTS = $(patsubst %.c, %.o, $(wildcard *.c))
HEADERS = $(wildcard *.h)

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -I$(INCLUDES1) -I$(INCLUDES2) -c $< -o $@ 

.PRECIOUS: $(TARGETS) $(OBJECTS)

bench-malloc-thread: $(OBJECTS)
	$(CC) $@.o json-lib.o -I$(INCLUDES1) -I$(INCLUDES2) -Wall $(LIBS) -o $@

bench-malloc-thread-lab: $(OBJECTS)
	$(CC) $@.o json-lib.o -I$(INCLUDES1) -I$(INCLUDES2) -Wall $(LIBS) -L$(SHAREDLIBS) -o $@ -lalloc

clean:
	-rm -f *.o
	-rm -f $(TARGETS)
