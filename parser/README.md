# Analisador Sintático - Lua
#### Desenvolvido por Melissa Pereira Guarilha.

Este programa tem como finalidade construir um analisador sintático para a linguagem de programação [Lua](https://www.lua.org).

<!-- ## Table of Contents -->
* [Geral](#geral)
* [Run](#run)
* [Testes](#testes)
<br>

## Geral
A estrutura do programa está definida em três arquivos principais, sendo estes:
* parser.lua (script contendo o analisador sintático);
* print_prog.lua (script contendo o print da árvore gerada no analisador sintático);
* main.lua (script contendo a execução do analisador sintático printado).

A saída retornada pelo programa imprime na tela a árvore gerada pelo analisador sintático de um arquivo passado como parâmetro.


## Run
Para rodar o programa, execute utilizando o [Lua](https://www.lua.org):
```bash
lua main.lua < "file_to_parser"
```

## Testes
Neste caso, usei como base para teste um arquuivo *.txt* que contém comandos em *Lua*:
```bash
lua main.lua < "parser_texts.txt"
```