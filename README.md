# Compilador para Linguagem de Script de Jogo

Este projeto é um interpretador para uma linguagem de script simples, desenvolvida com foco em lógica de jogos. Ele utiliza **Flex** para a análise léxica e **Bison** para a análise sintática, gerando uma Árvore Sintática Abstrata (AST) que é avaliada em tempo de execução.

## Funcionalidades da Linguagem

A linguagem suporta as seguintes construções:

  - **Condicional**: `VERIFICA <condição> EXECUTA <statement> [ALTERNATIVA <statement>]`
  - **Laço de Repetição (while)**: `REPETE <condição> <statement>`
  - **Laço de Contagem (for)**: `CONTAGEM (<inicialização>; <condição>; <incremento>) { <lista_de_statements> }`
  - `MOSTRAR_STATUS(valor)`: Imprime um valor no console.
  - `RAIZ(valor)`: Retorna a raiz quadrada do valor.
  - `EXP(valor)`: Retorna o exponencial do valor.
  - `LOG(valor)`: Retorna o logaritmo natural do valor.

## Estrutura dos Arquivos


## Como Compilar e Executar

### Pré-requisitos


### Compilação

Para compilar o projeto, basta executar o comando `make` no terminal, dentro do diretório do projeto.

```sh
make
```

Isso irá gerar o executável `compilador_jogo`.

### Limpeza

Para remover os arquivos gerados (executável e arquivos objeto), use o comando:

```sh
make clean
```

### Execução

Execute o compilador a partir do terminal:

```sh
./compilador_jogo
```

O programa iniciará um prompt interativo (`> `), onde você pode digitar os comandos da linguagem de script. Cada comando ou expressão será executado após pressionar Enter.

## Exemplos de Código

Os exemplos a seguir são baseados no arquivo [testes.txt](testes.txt).

### Atribuição e Impressão

```gamescript
// Atribui valores às variáveis vida e mana
vida = 100
mana = 50

// Imprime o valor da variável 'vida'
MOSTRAR_STATUS(vida)
```

### Estrutura Condicional `VERIFICA`

```gamescript
dano = 75
VERIFICA dano > vida EXECUTA { MOSTRAR_STATUS(0) } ALTERNATIVA { MOSTRAR_STATUS(vida - dano) }
```

### Laço de Contagem `CONTAGEM`

```gamescript
turnos = 0
CONTAGEM (i = 1; i <= 5; i = i + 1) {
    turnos = turnos + 1;
    MOSTRAR_STATUS(turnos)
}
```

### Laço de Repetição `REPETE`

```gamescript
energia = 3
REPETE energia > 0 {
    MOSTRAR_STATUS(energia);
    energia = energia - 1
}
```
