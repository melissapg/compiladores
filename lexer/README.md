# Analisador Léxico - Lua

Este programa tem como finalidade construir um analisador léxico para a linguagem de programação [Lua](https://www.lua.org).

<!-- ## Table of Contents -->
* [Geral](#geral)
* [Setup](#setup)
* [Testes](#testes)
* [Considerações Finais](#considerações-finais)
<br>

## Geral
A estrutura do programa está definida em dois arquivos principais, sendo estes:
* lexer.lua (script contendo o analisador léxico);
* main.lua (script contendo a execução do analisador léxico).

A saída retornada pelo programa imprime na tela os tokens¹ do arquivo passado como parâmetro.

¹Um token contém: linha, coluna, token e valor (este último sendo opcional).

## Setup
Para rodar o programa, execute utilizando o [Lua](https://www.lua.org):
```bash
lua main.lua < "file_to_lexer.lua"
```

## Testes
Além dos próprios arquivos _'main.lua'_ e _'lexer.lua'_ serem bons casos de teste, há também um arquivo específico para executar testes unitários do lexer chamado _'lexer_tests.lua'_.

Para rodar os testes, instale a biblioteca [luaunit](https://luaunit.readthedocs.io/en/luaunit_v3_2_1/) com o auxílio do gerenciador de pacotes [LuaRocks](https://luarocks.org):
```bash
luarocks install luaunit
```
Após a instalação, execute:
```bash
lua lexer_tests.lua
```

## Considerações Finais
O ponto de dificuldade mais importante enfrentado neste trabalho se deu pelo fato de, por este programa ter sido escrito através do [Visual Studio Code](https://code.visualstudio.com) em ambiente Windows, os marcadores de 'nova linha' (\n e \r) foram duplicados (e por vezes triplicados, quadriplicados...) quando haviam ocorrências de comentários simples com o uso de *--*.

O problema acarretou em uma dificuldade de categorizar corretamente o número da linha identificadora do token.