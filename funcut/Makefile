CC = gcc
CFLAGS = -O0 -Wall -g

sbj:
	$(CC) $(CFLAGS) -o sbj.o -c subject0.c

sbjpie:
	$(CC) $(CFLAGS) -pie -o sbjpie.o -c subject0.c

sbjso:
	$(CC) $(CFLAGS) -shared -o sbj.so sbjpie.o

fc0:
	$(CC) $(CFLAGS) -o fc0 funcut0.c
