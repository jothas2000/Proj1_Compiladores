%{
#include "jogo.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <math.h>

int yylex();
void yyerror(const char *s, ...);
%}

%union { double d; struct symbol *s; struct ast *a; int fn; }

%token <d> NUMBER
%token <s> NAME
%token <fn> FUNC CMP
%token EOL VERIFICA EXECUTA ALTERNATIVA REPETE CONTAGEM E OU

%right '='
%left E OU
%left '+' '-'
%left '*' '/' '%'
%nonassoc CMP
%nonassoc UMINUS

%type <a> exp stmt stmtlist inner_stmt_list

%start calclist

%%

calclist: | calclist EOL { printf("> "); } | calclist stmt EOL { if ($2) { eval($2); treefree($2); } printf("> "); } | calclist error EOL { yyerrok; printf("> "); } ;

stmt:     exp { $$ = $1; }
        | VERIFICA exp EXECUTA stmtlist { $$ = newflow('I', $2, $4, NULL); }
        | VERIFICA exp EXECUTA stmtlist ALTERNATIVA stmtlist { $$ = newflow('I', $2, $4, $6); }
        | REPETE exp stmtlist { $$ = newflow('W', $2, $3, NULL); }
        | CONTAGEM '(' exp ';' exp ';' exp ')' stmtlist { $$ = newfor($3, $5, $7, $9); }
        | FUNC '(' exp ')' { $$ = newfunc($1, $3); }
        ;

// CORREÇÃO PARA PERMITIR QUEBRAS DE LINHA DENTRO DE BLOCOS
opt_eols: /* Vazio */ | opt_eols EOL ;

stmtlist: stmt { $$ = $1; }
        | '{' opt_eols inner_stmt_list opt_eols '}' { $$ = $3; }
        | '{' opt_eols '}' { $$ = NULL; }
        ;

// CORREÇÃO FINAL: Permite quebras de linha (opt_eols) depois de um ';'
inner_stmt_list: stmt { $$ = $1; }
               | inner_stmt_list ';' opt_eols stmt { $$ = newast('L', $1, $4); }
               | inner_stmt_list ';' opt_eols      { $$ = $1; } // Permite ';' no final do bloco
               ;

exp:      NUMBER { $$ = newnum($1); }
        | NAME { $$ = newref($1); }
        | NAME '=' exp { $$ = newasgn($1, $3); }
        | exp '+' exp { $$ = newast('+', $1, $3); }
        | exp '-' exp { $$ = newast('-', $1, $3); }
        | exp '*' exp { $$ = newast('*', $1, $3); }
        | exp '/' exp { $$ = newast('/', $1, $3); }
        | exp '%' exp { $$ = newast('%', $1, $3); }
        | exp CMP exp { $$ = newcmp($2, $1, $3); }
        | exp E exp { $$ = newast('E', $1, $3); }
        | exp OU exp { $$ = newast('O', $1, $3); }
        | FUNC '(' exp ')' { $$ = newfunc($1, $3); }
        | '(' exp ')' { $$ = $2; }
        | '-' exp %prec UMINUS { $$ = newast('M', $2, NULL); }
        ;
%%
/* O resto do código (funções C) permanece o mesmo */
#ifndef strdup
char *strdup(const char *s) { char *d = malloc(strlen(s) + 1); if (d == NULL) return NULL; strcpy(d, s); return d; }
#endif
struct symbol symtab[NHASH];
static unsigned symhash(char *sym) { unsigned int hash = 0; unsigned c; while((c = *sym++)) hash = hash * 9 ^ c; return hash; }
struct symbol *lookup(char* sym) { struct symbol *sp = &symtab[symhash(sym) % NHASH]; int scount = NHASH; while(--scount >= 0) { if(sp->name && !strcmp(sp->name, sym)) { return sp; } if(!sp->name) { sp->name = strdup(sym); sp->value = 0.0; return sp; } if(++sp >= symtab + NHASH) sp = symtab; } yyerror("symbol table overflow\n"); abort(); }
struct ast *newast(int nodetype, struct ast *l, struct ast *r) { struct ast *a = malloc(sizeof(struct ast)); if(!a) { yyerror("out of space"); exit(0); } a->nodetype = nodetype; a->l = l; a->r = r; return a; }
struct ast *newnum(double d) { struct numval *a = malloc(sizeof(struct numval)); if(!a) { yyerror("out of space"); exit(0); } a->nodetype = 'N'; a->number = d; return (struct ast *)a; }
struct ast *newcmp(int cmptype, struct ast *l, struct ast *r) { struct ast *a = newast(cmptype, l, r); a->nodetype = '0' + cmptype; return a; }
struct ast *newfunc(int functype, struct ast *l) { struct fncall *a = malloc(sizeof(struct fncall)); if(!a) { yyerror("out of space"); exit(0); } a->nodetype = 'C'; a->l = l; a->functype = (enum bifs)functype; return (struct ast *)a; }
struct ast *newref(struct symbol *s) { struct symref *a = malloc(sizeof(struct symref)); if(!a) { yyerror("out of space"); exit(0); } a->nodetype = 'S'; a->s = s; return (struct ast *)a; }
struct ast *newasgn(struct symbol *s, struct ast *v) { struct symasgn *a = malloc(sizeof(struct symasgn)); if(!a) { yyerror("out of space"); exit(0); } a->nodetype = '='; a->s = s; a->v = v; return (struct ast *)a; }
struct ast *newflow(int nodetype, struct ast *cond, struct ast *tl, struct ast *el) { struct flow *a = malloc(sizeof(struct flow)); if(!a) { yyerror("out of space"); exit(0); } a->nodetype = nodetype; a->cond = cond; a->tl = tl; a->el = el; return (struct ast *)a; }
struct ast *newfor(struct ast *init, struct ast *cond, struct ast *inc, struct ast *stmts) { struct forloop *a = malloc(sizeof(struct forloop)); if(!a) { yyerror("out of space"); exit(0); } a->nodetype = 'F'; a->init = init; a->cond = cond; a->inc = inc; a->stmts = stmts; return (struct ast *)a; }
void treefree(struct ast *a) { if(!a) return; switch(a->nodetype) { case '+': case '-': case '*': case '/': case '%': case 'E': case 'O': case '1': case '2': case '3': case '4': case '5': case '6': case 'L': treefree(a->r); case 'C': case 'M': treefree(a->l); case 'N': case 'S': break; case '=': treefree(((struct symasgn *)a)->v); break; case 'I': case 'W': treefree(((struct flow *)a)->cond); if(((struct flow *)a)->tl) treefree(((struct flow *)a)->tl); if(((struct flow *)a)->el) treefree(((struct flow *)a)->el); break; case 'F': treefree(((struct forloop *)a)->init); treefree(((struct forloop *)a)->cond); treefree(((struct forloop *)a)->inc); treefree(((struct forloop *)a)->stmts); break; default: printf("internal error: free bad node %c\n", a->nodetype); } free(a); }
double eval(struct ast *a) { double v = 0.0; if(!a) { yyerror("internal error, null eval"); return 0.0; } switch(a->nodetype) { case 'N': v = ((struct numval *)a)->number; break; case 'S': v = ((struct symref *)a)->s->value; break; case '=': v = ((struct symasgn *)a)->s->value = eval(((struct symasgn *)a)->v); break; case '+': v = eval(a->l) + eval(a->r); break; case '-': v = eval(a->l) - eval(a->r); break; case '*': v = eval(a->l) * eval(a->r); break; case '/': v = eval(a->l) / eval(a->r); break; case '%': v = fmod(eval(a->l), eval(a->r)); break; case 'M': v = -eval(a->l); break; case '1': v = (eval(a->l) > eval(a->r))  ? 1 : 0; break; case '2': v = (eval(a->l) < eval(a->r))  ? 1 : 0; break; case '3': v = (eval(a->l) != eval(a->r)) ? 1 : 0; break; case '4': v = (eval(a->l) == eval(a->r)) ? 1 : 0; break; case '5': v = (eval(a->l) >= eval(a->r)) ? 1 : 0; break; case '6': v = (eval(a->l) <= eval(a->r)) ? 1 : 0; break; case 'E': v = (eval(a->l) != 0 && eval(a->r) != 0) ? 1 : 0; break; case 'O': v = (eval(a->l) != 0 || eval(a->r) != 0) ? 1 : 0; break; case 'I': if(eval(((struct flow *)a)->cond) != 0) { if(((struct flow *)a)->tl) v = eval(((struct flow *)a)->tl); } else { if(((struct flow *)a)->el) v = eval(((struct flow *)a)->el); } break; case 'W': if(((struct flow *)a)->tl) { while(eval(((struct flow *)a)->cond) != 0) v = eval(((struct flow *)a)->tl); } break; case 'F': for(eval(((struct forloop*)a)->init); eval(((struct forloop*)a)->cond); eval(((struct forloop*)a)->inc)) { v = eval(((struct forloop*)a)->stmts); } break; case 'L': eval(a->l); v = eval(a->r); break; case 'C': switch(((struct fncall *)a)->functype) { case B_print: printf("= %g\n", eval(a->l)); v = 0.0; break; case B_sqrt:  v = sqrt(eval(a->l)); break; case B_exp:   v = exp(eval(a->l)); break; case B_log:   v = log(eval(a->l)); break; default: yyerror("Unknown built-in function %d", ((struct fncall *)a)->functype); break; } break; default: printf("internal error: bad node %c\n", a->nodetype); } return v; }
void yyerror(const char *s, ...) { va_list ap; va_start(ap, s); fprintf(stderr, "%d: error: ", yylineno); vfprintf(stderr, s, ap); fprintf(stderr, "\n"); }
int main() { printf("> "); return yyparse(); }