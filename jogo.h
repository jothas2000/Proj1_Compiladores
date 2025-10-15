/*
 * Cabeçalho para a Linguagem de Script de Jogo
 * Define as estruturas da AST, tabela de símbolos e declarações de funções.
 */

// Estrutura para a tabela de símbolos
struct symbol {
  char *name;
  double value;
  struct ast *func;
  struct symlist *syms;
};

// Tamanho fixo da tabela hash
#define NHASH 9997
extern struct symbol symtab[NHASH];

// Lista de símbolos, para argumentos de funções
struct symlist {
  struct symbol *sym;
  struct symlist *next;
};

// Tipos de nós da Árvore Sintática Abstrata (AST)
/*
 * + - * / |
 * 0-7: operadores de comparação
 * M: menos unário
 * L: lista de statements
 * I: VERIFICA (IF)
 * W: REPETE (WHILE)
 * F: CONTAGEM (FOR)
 * N: número
 * =: atribuição
 * S: referência a símbolo
 * C: chamada de função
 */
enum bifs { B_sqrt = 1, B_exp, B_log, B_print }; // Funções pré-definidas

// Estrutura de um nó da AST
struct ast {
  int nodetype;
  struct ast *l;
  struct ast *r;
};

// Estrutura para funções pré-definidas e chamadas
struct fncall {
  int nodetype; // 'C' para chamada
  struct ast *l;
  enum bifs functype;
};

// Estrutura para controle de fluxo (IF, WHILE)
struct flow {
  int nodetype; // 'I' ou 'W'
  struct ast *cond;
  struct ast *tl; // then list
  struct ast *el; // else list
};

// Estrutura para o comando FOR
struct forloop {
    int nodetype; // 'F'
    struct ast *init;
    struct ast *cond;
    struct ast *inc;
    struct ast *stmts;
};

// Estrutura para números
struct numval {
  int nodetype; // 'N'
  double number;
};

// Estrutura para referência a símbolos
struct symref {
  int nodetype; // 'S'
  struct symbol *s;
};

// Estrutura para atribuição
struct symasgn {
  int nodetype; // '='
  struct symbol *s;
  struct ast *v;
};

// Funções para construir a AST
struct ast *newast(int nodetype, struct ast *l, struct ast *r);
struct ast *newcmp(int cmptype, struct ast *l, struct ast *r);
struct ast *newfunc(int functype, struct ast *l);
struct ast *newcall(struct symbol *s, struct ast *l);
struct ast *newref(struct symbol *s);
struct ast *newasgn(struct symbol *s, struct ast *v);
struct ast *newnum(double d);
struct ast *newflow(int nodetype, struct ast *cond, struct ast *tl, struct ast *el);
struct ast *newfor(struct ast *init, struct ast *cond, struct ast *inc, struct ast *stmts);

// Funções da tabela de símbolos
struct symbol *lookup(char*);
struct symlist *newsymlist(struct symbol *sym, struct symlist *next);
void symlistfree(struct symlist *sl);

// Função principal de avaliação
double eval(struct ast *);
void treefree(struct ast *);

// Funções do lexer
extern int yylineno;
void yyerror(const char *s, ...);