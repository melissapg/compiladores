import sys


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


def calc_exp(n1, n2, op):
    if op == 'ADD':
        return n2 + n1
    elif op == 'SUB':
        return n2 - n1
    elif op == 'MUL':
        return n2 * n1
    elif op == 'DIV':
        if n1 == 0:
            print(f"ZeroDivisionError: division by zero.")
            exit(True)
        else:    
            return n2 / n1
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


def eval(file):
    stack = Stack()
    variables = {}  # variáveis globais

    for line in file.readlines():
        action = line.split()[0]
        if action == 'NUMBER':
            stack.push_stack(float(line.split()[1]))
        elif action == 'NEG':
            n1 = stack.pop_stack()
            stack.push_stack(calc_exp(n1, None, action))
        elif action == 'SETGLOBAL':
            var = stack.pop_stack()
            variables[line.split()[1]] = var
        elif action == 'GETGLOBAL':
            stack.push_stack(float(variables[line.split()[1]]))
        elif action == 'RETURN':
            n1 = stack.pop_stack()
            print(n1)
            break
        elif action in ['ADD', 'SUB', 'MUL', 'DIV', 'MOD', 'NEG']:
            n1 = stack.pop_stack()
            n2 = stack.pop_stack()
            stack.push_stack(calc_exp(n1, n2, action))
        else:
            print(f"Error: the action {action} doesn't exists.")
            exit(True)

eval(f)
