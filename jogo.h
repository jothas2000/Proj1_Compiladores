/*
 * Cabeçalho para a Linguagem de Script de Jogo
 * Define as estruturas da AST, tabela de símbolos e funções globais.
 */

// Estrutura para um símbolo (variável ou função)
struct symbol {
    char *name;
    double value;
};

// Tamanho da tabela de hash para os símbolos
#define NHASH 9997

// Tabela de símbolos externa
extern struct symbol symtab[NHASH];

// Enum para funções pré-definidas (built-in functions)
enum bifs {
    B_sqrt = 1,
    B_exp,
    B_log,
    B_print
};

// Estrutura base da Árvore Sintática Abstrata (AST)
struct ast {
    int nodetype;
    struct ast *l;
    struct ast *r;
};

// Chamada de função
struct fncall {
    int nodetype;       // Tipo 'C'
    struct ast *l;
    enum bifs functype;
};

// Estrutura para fluxo de controle (IF, WHILE)
struct flow {
    int nodetype;       // Tipo 'I' ou 'W'
    struct ast *cond;
    struct ast *tl;     // Then-list ou Do-list
    struct ast *el;     // Else-list (opcional)
};

// Estrutura para o laço FOR
struct forloop {
    int nodetype;       // Tipo 'F'
    struct ast *init;
    struct ast *cond;
    struct ast *inc;
    struct ast *stmts;
};

// Valor numérico
struct numval {
    int nodetype;       // Tipo 'N'
    double number;
};

// Referência a um símbolo
struct symref {
    int nodetype;       // Tipo 'S'
    struct symbol *s;
};

// Atribuição a um símbolo
struct symasgn {
    int nodetype;       // Tipo '='
    struct symbol *s;
    struct ast *v;
};

/* Protótipos das funções de construção da AST */
struct ast *newast(int nodetype, struct ast *l, struct ast *r);
struct ast *newcmp(int cmptype, struct ast *l, struct ast *r);
struct ast *newfunc(int functype, struct ast *l);
struct ast *newref(struct symbol *s);
struct ast *newasgn(struct symbol *s, struct ast *v);
struct ast *newnum(double d);
struct ast *newflow(int nodetype, struct ast *cond, struct ast *tl, struct ast *el);
struct ast *newfor(struct ast *init, struct ast *cond, struct ast *inc, struct ast *stmts);

/* Protótipos de outras funções */
struct symbol *lookup(char*);
double eval(struct ast *);
void treefree(struct ast *);

// Função do analisador léxico e variável de linha
extern int yylineno;
int yylex();
void yyerror(const char *s, ...);