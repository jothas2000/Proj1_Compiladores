/*
 * Analisador Sintático para a Linguagem de Script de Jogo
 */
%{
#include "jogo.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

/* Prototipos */
struct ast *newast(int nodetype, struct ast *l, struct ast *r);
struct ast *newnum(double d);

void yyerror(const char *s, ...);
%}

/* Union para armazenar os diferentes tipos de valores dos tokens */
%union {
  double d;             /* valor de um NUMBER */
  struct symbol *s;     /* ponteiro para a tabela de simbolos */
  struct ast *a;        /* ponteiro para um nó da AST */
  int fn;               /* código de uma função/comparação */
}

/* Declaração de tokens e seus tipos */
%token <d> NUMBER
%token <s> NAME
%token <fn> FUNC
%token <fn> CMP
%token EOL
%token VERIFICA EXECUTA ALTERNATIVA REPETE CONTAGEM CRIAR
%token E OU

/* Associatividade e precedência dos operadores */
%nonassoc CMP
%right '='
%left E OU        /* Adicionado E/OU com baixa precedência */
%left '+' '-'
%left '*' '/' '%'
%nonassoc UMINUS /* Menos unário */

/* Tipos dos não-terminais */
%type <a> stmt stmtlist exp

/* Ponto de entrada da gramática */
%start calclist

%%

calclist: /* vazio */
        | calclist EOL { printf("= 0.0\n"); }
        | calclist stmt EOL { if ($2) { eval($2); treefree($2); printf("= %4.4g\n", eval($2)); } }
        | calclist error EOL { yyerrok; }
        ;

stmt:     exp { $$ = $1; }
        | VERIFICA exp EXECUTA stmtlist
          { $$ = newflow('I', $2, $4, NULL); }
        | VERIFICA exp EXECUTA stmtlist ALTERNATIVA stmtlist
          { $$ = newflow('I', $2, $4, $6); }
        | REPETE exp stmtlist
          { $$ = newflow('W', $2, $3, NULL); }
        | CONTAGEM '(' exp ';' exp ';' exp ')' '{' stmtlist '}'
        { $$ = newfor($3, $5, $7, $10); }
        ;

stmtlist: stmt { $$ = $1; }
        | stmtlist ';' stmt { $$ = newast('L', $1, $3); }
        ;

exp:      NUMBER { $$ = newnum($1); }
        | NAME { $$ = newref($1); }
        | NAME '=' exp { $$ = newasgn($1, $3); }
        | FUNC '(' exp ')' { $$ = newfunc($1, $3); }
        | exp '+' exp { $$ = newast('+', $1, $3); }
        | exp '-' exp { $$ = newast('-', $1, $3); }
        | exp '*' exp { $$ = newast('*', $1, $3); }
        | exp '/' exp { $$ = newast('/', $1, $3); }
        | exp '%' exp { $$ = newast('%', $1, $3); }
        | exp CMP exp { $$ = newcmp($2, $1, $3); }
        | exp E exp   { $$ = newast('E', $1, $3); } /* Regra para AND */
        | exp OU exp  { $$ = newast('O', $1, $3); } /* Regra para OR */
        | '(' exp ')' { $$ = $2; }
        | '-' exp %prec UMINUS { $$ = newast('M', $2, NULL); }
        ;

%%

/* Código C auxiliar */
#include <string.h>
#include <math.h>

/* Tabela de símbolos */
struct symbol symtab[NHASH];

/* Hash a string */
static unsigned symhash(char *sym) {
    unsigned int hash = 0;
    unsigned c;
    while((c = *sym++)) hash = hash*9 ^ c;
    return hash;
}

struct symbol *lookup(char* sym) {
    struct symbol *sp = &symtab[symhash(sym)%NHASH];
    int scount = NHASH;

    while(--scount >= 0) {
        if(sp->name && !strcmp(sp->name, sym)) { return sp; }
        if(!sp->name) {
            sp->name = strdup(sym);
            sp->value = 0;
            sp->func = NULL;
            sp->syms = NULL;
            return sp;
        }
        if(++sp >= symtab+NHASH) sp = symtab;
    }
    yyerror("symbol table overflow\n");
    abort();
}

/* Funções de construção da AST */
struct ast *newast(int nodetype, struct ast *l, struct ast *r) {
    struct ast *a = malloc(sizeof(struct ast));
    if(!a) { yyerror("out of space"); exit(0); }
    a->nodetype = nodetype;
    a->l = l;
    a->r = r;
    return a;
}

struct ast *newnum(double d) {
    struct numval *a = malloc(sizeof(struct numval));
    if(!a) { yyerror("out of space"); exit(0); }
    a->nodetype = 'N';
    a->number = d;
    return (struct ast *)a;
}

struct ast *newcmp(int cmptype, struct ast *l, struct ast *r) {
    struct ast *a = malloc(sizeof(struct ast));
    if(!a) { yyerror("out of space"); exit(0); }
    a->nodetype = '0' + cmptype;
    a->l = l;
    a->r = r;
    return a;
}

struct ast *newfunc(int functype, struct ast *l) {
    struct fncall *a = malloc(sizeof(struct fncall));
    if(!a) { yyerror("out of space"); exit(0); }
    a->nodetype = 'C';
    a->l = l;
    a->functype = functype;
    return (struct ast *)a;
}

struct ast *newref(struct symbol *s) {
    struct symref *a = malloc(sizeof(struct symref));
    if(!a) { yyerror("out of space"); exit(0); }
    a->nodetype = 'S';
    a->s = s;
    return (struct ast *)a;
}

struct ast *newasgn(struct symbol *s, struct ast *v) {
    struct symasgn *a = malloc(sizeof(struct symasgn));
    if(!a) { yyerror("out of space"); exit(0); }
    a->nodetype = '=';
    a->s = s;
    a->v = v;
    return (struct ast *)a;
}

struct ast *newflow(int nodetype, struct ast *cond, struct ast *tl, struct ast *el) {
    struct flow *a = malloc(sizeof(struct flow));
    if(!a) { yyerror("out of space"); exit(0); }
    a->nodetype = nodetype;
    a->cond = cond;
    a->tl = tl;
    a->el = el;
    return (struct ast *)a;
}

struct ast *newfor(struct ast *init, struct ast *cond, struct ast *inc, struct ast *stmts) {
    struct forloop *a = malloc(sizeof(struct forloop));
    if(!a) { yyerror("out of space"); exit(0); }
    a->nodetype = 'F';
    a->init = init;
    a->cond = cond;
    a->inc = inc;
    a->stmts = stmts;
    return (struct ast *)a;
}

void treefree(struct ast *a) {
    if(!a) return;

    switch(a->nodetype) {
        case '+': case '-': case '*': case '/':
        case 'E': case 'O':
        case '1': case '2': case '3': case '4': case '5': case '6':
        case 'L':
            treefree(a->r);
        case 'C': case 'M':
            treefree(a->l);
        case 'N': case 'S':
            break;
        case '=':
            free( ((struct symasgn *)a)->v );
            break;
        case 'I': case 'W':
            free( ((struct flow *)a)->cond );
            if( ((struct flow *)a)->tl ) treefree( ((struct flow *)a)->tl );
            if( ((struct flow *)a)->el ) treefree( ((struct flow *)a)->el );
            break;
        case 'F':
            treefree( ((struct forloop *)a)->init );
            treefree( ((struct forloop *)a)->cond );
            treefree( ((struct forloop *)a)->inc );
            treefree( ((struct forloop *)a)->stmts );
            break;
        default: printf("internal error: free bad node %c\n", a->nodetype);
    }
    free(a);
}

double eval(struct ast *a) {
    double v = 0.0;
    if(!a) { yyerror("internal error, null eval"); return 0.0; }

    switch(a->nodetype) {
        case 'N': v = ((struct numval *)a)->number; break;
        case 'S': v = ((struct symref *)a)->s->value; break;
        case '=': v = ((struct symasgn *)a)->s->value = eval(((struct symasgn *)a)->v); break;
        case '+': v = eval(a->l) + eval(a->r); break;
        case '-': v = eval(a->l) - eval(a->r); break;
        case '*': v = eval(a->l) * eval(a->r); break;
        case '/': v = eval(a->l) / eval(a->r); break;
        case '%': v = fmod(eval(a->l), eval(a->r)); break;
        case 'M': v = -eval(a->l); break;
        case '1': v = (eval(a->l) > eval(a->r))? 1 : 0; break;
        case '2': v = (eval(a->l) < eval(a->r))? 1 : 0; break;
        case '3': v = (eval(a->l) != eval(a->r))? 1 : 0; break;
        case '4': v = (eval(a->l) == eval(a->r))? 1 : 0; break;
        case '5': v = (eval(a->l) >= eval(a->r))? 1 : 0; break;
        case '6': v = (eval(a->l) <= eval(a->r))? 1 : 0; break;
        case 'E': v = (eval(a->l) && eval(a->r))? 1 : 0; break;
        case 'O': v = (eval(a->l) || eval(a->r))? 1 : 0; break;

        case 'I':
            if(eval(((struct flow *)a)->cond) != 0) {
                if(((struct flow *)a)->tl) v = eval(((struct flow *)a)->tl);
                else v = 0.0;
            } else {
                if(((struct flow *)a)->el) v = eval(((struct flow *)a)->el);
                else v = 0.0;
            }
            break;
        case 'W':
            v = 0.0;
            if(((struct flow *)a)->tl) {
                while(eval(((struct flow *)a)->cond) != 0)
                    v = eval(((struct flow *)a)->tl);
            }
            break;
        case 'F':
            eval(((struct forloop*)a)->init);
            while(eval(((struct forloop*)a)->cond) != 0) {
                eval(((struct forloop*)a)->stmts);
                eval(((struct forloop*)a)->inc);
            }
            break;
        case 'L': eval(a->l); v = eval(a->r); break;
        case 'C':
            switch(((struct fncall *)a)->functype) {
                case B_print: v = printf("%4.4g\n", eval(a->l)); break;
                case B_sqrt: v = sqrt(eval(a->l)); break;
                case B_exp: v = exp(eval(a->l)); break;
                case B_log: v = log(eval(a->l)); break;
                default: yyerror("Função desconhecida %d", ((struct fncall *)a)->functype); break;
            }
            break;
        default: printf("internal error: bad node %c\n", a->nodetype);
    }
    return v;
}

void yyerror(const char *s, ...) {
    va_list ap;
    va_start(ap, s);
    fprintf(stderr, "%d: error: ", yylineno);
    vfprintf(stderr, s, ap);
    fprintf(stderr, "\n");
}

int main() {
    printf("> ");
    return yyparse();
}