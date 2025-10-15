# Makefile para o compilador da Linguagem de Jogo (VERSÃO CORRIGIDA)
CC=gcc
CFLAGS=-std=c99 -Wall -lm

TARGET=compilador_jogo

# Lista de arquivos objeto
OBJS = jogo_lex.o jogo_syntax.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS)

# Regra para compilar os .o
jogo_lex.o: jogo_lex.c
	$(CC) $(CFLAGS) -c jogo_lex.c

jogo_syntax.o: jogo_syntax.c
	$(CC) $(CFLAGS) -c jogo_syntax.c

# Regra para gerar o C do flex
# Depende de jogo.tab.h
jogo_lex.c: jogo_lex.l jogo.tab.h
	flex -o jogo_lex.c jogo_lex.l

# Regra para gerar o C do bison e o header
# Esta regra cria 'jogo_syntax.c' e 'jogo.tab.h'
# E depois renomeia 'jogo_syntax.tab.h' para 'jogo.tab.h'
jogo_syntax.c jogo.tab.h: jogo_syntax.y
	bison -d -o jogo_syntax.c jogo_syntax.y
	mv jogo_syntax.tab.h jogo.tab.h

# Regra para limpar os arquivos gerados
clean:
	rm -f $(TARGET) $(OBJS) jogo_lex.c jogo_syntax.c jogo.tab.h