CC = gcc
CFLAGS = -std=c99 -Wall
LDFLAGS = -lm
TARGET = compilador_jogo
OBJS = jogo_lex.o jogo_syntax.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS) $(LDFLAGS)

jogo_lex.o: jogo_lex.c jogo.tab.h
	$(CC) $(CFLAGS) -c jogo_lex.c

jogo_syntax.o: jogo_syntax.c
	$(CC) $(CFLAGS) -c jogo_syntax.c

jogo_lex.c: jogo_lex.l
	flex -o jogo_lex.c jogo_lex.l

jogo_syntax.c jogo.tab.h: jogo_syntax.y
	bison -d --header=jogo.tab.h -o jogo_syntax.c jogo_syntax.y

clean:
	rm -f $(TARGET) $(OBJS) jogo_lex.c jogo_syntax.c jogo.tab.h