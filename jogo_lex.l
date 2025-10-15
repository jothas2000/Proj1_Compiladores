%option noyywrap nodefault yylineno

%{
#include "jogo.h"
#include "jogo.tab.h"
#include <string.h>
#include <stdlib.h>
%}

EXP ([Ee][-+]?[0-9]+)

%%

[ \t]      ;
"//".*     ;
"+"        { return yytext[0]; }
"-"        { return yytext[0]; }
"*"        { return yytext[0]; }
"/"        { return yytext[0]; }
"%"        { return yytext[0]; }
"="        { return yytext[0]; }
";"        { return yytext[0]; }
"("        { return yytext[0]; }
")"        { return yytext[0]; }
"{"        { return yytext[0]; }
"}"        { return yytext[0]; }
">"        { yylval.fn = 1; return CMP; }
"<"        { yylval.fn = 2; return CMP; }
"<>"       { yylval.fn = 3; return CMP; }
"=="       { yylval.fn = 4; return CMP; }
">="       { yylval.fn = 5; return CMP; }
"<="       { yylval.fn = 6; return CMP; }
"VERIFICA"    { return VERIFICA; }
"EXECUTA"     { return EXECUTA; }
"ALTERNATIVA" { return ALTERNATIVA; }
"REPETE"      { return REPETE; }
"CONTAGEM"    { return CONTAGEM; }
"E"           { return E; }
"OU"          { return OU; }
"RAIZ"           { yylval.fn = B_sqrt; return FUNC; }
"EXP"            { yylval.fn = B_exp; return FUNC; }
"LOG"            { yylval.fn = B_log; return FUNC; }
"MOSTRAR_STATUS" { yylval.fn = B_print; return FUNC; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.s = lookup(yytext); return NAME; }
[0-9]+("."[0-9]*)?({EXP})? |
"."[0-9]+({EXP})?      { yylval.d = atof(yytext); return NUMBER; }
\n        { return EOL; }
.         { yyerror("Caractere desconhecido '%c'", *yytext); }

%%