parser = require("parser")  -- modulo parser
print_prog = require("print_prog")  -- modulo de print da arvore

texto = io.read("a")

parser.init_parser(texto)
prog = parser.parseProg()

print()  -- excluir
print()  -- excluir

print_prog.printProg(prog)
