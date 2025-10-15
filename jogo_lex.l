/*
 * Analisador Léxico para a Linguagem de Script de Jogo
 */
%option noyywrap nodefault yylineno

%{
#include "jogo.h"
#include "jogo.tab.h" // Arquivo gerado pelo Bison
#include <math.h>
%}

/* Regex para expoente de float */
EXP ([Ee][-+]?[0-9]+)

%%

/* Ignora espaços em branco e tabulações */
[ \t]       ;

/* Comentários de linha única */
"//".* ;

/* Operadores de caractere único */
"+" | "-" | "*" | "/" | "=" | "," | ";" | "(" | ")" | "{" | "}" | "%" { return yytext[0]; }

/* Operadores de comparação */
">"     { yylval.fn = 1; return CMP; }
"<"     { yylval.fn = 2; return CMP; }
"<>"    { yylval.fn = 3; return CMP; }
"=="    { yylval.fn = 4; return CMP; }
">="    { yylval.fn = 5; return CMP; }
"<="    { yylval.fn = 6; return CMP; }

/* Palavras-chave do jogo */
"VERIFICA"      { return VERIFICA; }
"EXECUTA"       { return EXECUTA; }
"ALTERNATIVA"   { return ALTERNATIVA; }
"REPETE"        { return REPETE; }
"CONTAGEM"      { return CONTAGEM; }
"CRIAR"         { return CRIAR; }
"E"             { return E; }
"OU"            { return OU; }

/* Funções pré-definidas */
"RAIZ"              { yylval.fn = B_sqrt; return FUNC; }
"EXP"               { yylval.fn = B_exp; return FUNC; }
"LOG"               { yylval.fn = B_log; return FUNC; }
"MOSTRAR_STATUS"    { yylval.fn = B_print; return FUNC; }

/* Nomes (variáveis, funções) */
[a-zA-Z][a-zA-Z0-9]* { yylval.s = lookup(yytext); return NAME; }

/* Números (float) */
[0-9]+"."[0-9]*{EXP}? | "."[0-9]+{EXP}? | [0-9]+{EXP}? { yylval.d = atof(yytext); return NUMBER; }

/* Fim de linha */
\n              { return EOL; }

/* Qualquer outro caractere é um erro */
.               { yyerror("Caractere desconhecido %c\n", *yytext); }

%%