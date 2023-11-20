import sys
import re


def list_instructions():
    """
    Cria uma lista de instruções a partir de um arquivo
    passado como argumento na chamada do programa.

    :return: Uma lista de instruções
    """
    prog_array = []  # array de instruções

    try:
        prog = sys.argv[1]
    except IndexError:
        print("Error: A file needs to be provided.\n")
        raise

    try:
        f = open(prog, "r")
    except (IOError, FileNotFoundError):
        print("FileNotFoundError: File not found.\n")
        raise

    for line in f.readlines():
        prog_array.append(line)
    return prog_array


class Stack:
    def __init__(self):
        self.stack = []

    def pop_stack(self):
        return self.stack.pop()

    def push_stack(self, value):
        self.stack.append(value)

    def top(self):
        return self.stack[-1]

    def empty(self):
        return False if self.stack else True


# class GlobalFunctions:


def calc_exp(n1, n2, op):
    if op == 'ADD':
        return n2 + n1
    elif op == 'SUB':
        return n2 - n1
    elif op == 'MUL':
        return n2 * n1
    elif op == 'IDIV':
        if n1 == 0:
            print(f"ZeroDivisionError: division by zero.")
            exit(True)
        else:    
            return n2 // n1
    elif op == 'MOD':
        if n1 == 0:
            print(f"ZeroDivisionError: division by zero.")
            exit(True)
        else:
            return n2 % n1
    elif op == 'NEG':
        return - n1
    else:
        print(f"Error: exp operation {op} doesn't exist.")
        exit(True)



def eval(prog):
    stack = Stack()
    # variables = GlobalFunctions().all()  # variáveis globais
    variables = {}

    for line in prog:
        instruction = line.split()[0]
        if instruction == 'NUMBER':
            stack.push_stack(int(line.split()[1]))
        elif instruction == 'NEG':
            n1 = stack.pop_stack()
            if type(n1) != int:
                print(f"TypeError: unsupported operand type(s) for {instruction}: 'int' and {type(n1)}")
                exit(True)
            stack.push_stack(calc_exp(n1, None, instruction))
        elif instruction == 'NIL':
            stack.push_stack(None)
        elif instruction == 'STRING':
            string = re.findall(r'"([^"\\]*(?:\\.[^"\\]*)*)"', line)[0]
            string = string.replace("@n", "\n").replace("@r", "\r").replace("@@", "@")  # add aqui o @q
            stack.push_stack(str(string))
        elif instruction == 'SETGLOBAL':
            var = stack.pop_stack()
            variables[line.split()[1]] = var
        elif instruction == 'GETGLOBAL':
            val = variables[line.split()[1]]
            if not val:  # isso tá ok?
                val = None
            stack.push_stack(val)
        elif instruction == 'NEW_TABLE':
            newtable = {}
            for _ in range(int(line.split()[1])):
                val = stack.pop_stack()
                key = stack.pop_stack()
                newtable[key] = val
            stack.push_stack(newtable)
        elif instruction == 'RETURN':  # remover!
            n1 = stack.pop_stack()
            print(n1)
            break
        elif instruction in ['ADD', 'SUB', 'MUL', 'IDIV', 'MOD']:
            n1 = stack.pop_stack()
            n2 = stack.pop_stack()
            if type(n1) != int or type(n2) != int:
                print(f"TypeError: unsupported operand type(s) for {instruction}: {type(n1)} and {type(n1)}")
                exit(True)
            stack.push_stack(calc_exp(n1, n2, instruction))
        else:
            print(f"Error: the instruction {instruction} doesn't exists.")
            exit(True)


#---------------------------------------------- EXECUÇÃO DO PROGRAMA ---------------------------------------

prog = list_instructions()
eval(prog)
