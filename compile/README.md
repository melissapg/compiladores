# Compilador - Lua
#### Desenvolvido por Melissa Pereira Guarilha.

Este programa tem como finalidade construir um compilador para a linguagem de programação [Lua](https://www.lua.org) e um executador em [Python](https://www.python.org).

<!-- ## Table of Contents -->
* [Geral](#geral)
* [Run](#run)
* [Testes](#testes)
<br>

## Geral
A estrutura do programa está definida em três arquivos principais, sendo estes:
* compile.lua (script contendo o compilador);
* vm.py (script contendo o executador do arquivo compilado).

A saída retornada pelo programa imprime na tela o resultado do programa compilado e executado.


## Run
Para rodar o programa, compile utilizando o [Lua](https://www.lua.org):
```bash
lua compile.lua < "file_to_compile" > "compiled_file".byte
```
e execute utilizando o [Python](https://www.python.org):
```bash
python vm.py "compiled_file".byte
```


## Testes
Neste caso, usei como base para teste um arquivo *.txt* que contém comandos em *Lua*:
```bash
lua main.lua < vm_tests.txt > prog.byte
python vm.py prog.byte
```