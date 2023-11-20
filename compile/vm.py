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


class FunçaoInterna:
    def index_error(self, func_name: str, args: list, n_args: int = 1):
        more_args = f' or {n_args}' if n_args != 1 else ''
        if len(args) < n_args:
            print(f"TypeError: {func_name}() takes 1{more_args} argument(s).")
            exit(True)

    def print(self, args: list, out: str = ''):
        out = ''.join(str(arg) for arg in args)
        return print(out)

    def tonumber(self, args: list):
        self.index_error('tonumber', args)
        try:
            return int(args[0])
        except ValueError:
            print(f'ValueError: invalid literal for int() with base 10: {args[0]}.')

    def tostring(self, args: list):
        self.index_error('tostring', args)
        return str(args[0])

    def type(self, args: list):
        self.index_error('type', args)
        return type(args[0])

    def string_byte(self, args: list):
        self.index_error('string_byte', args, 2)

        string = args[0]
        idx = 1 if len(args) < 2 else args[1]
        if not isinstance(string, str):
            print(f"Error: Bad argument to 'byte' (string expected, got {type(string)})")
            exit(True)
        if idx >= 1 and idx <= len(string) and isinstance(idx, int):
            return ord(string[idx - 1])
        else:
            return None

    def string_len(self, args: list):
        self.index_error('string_len', args)
        if not isinstance(args[0], str):
            print(f"Error: Bad argument to 'len' (string expected, got {type(args[0])})")
            exit(True)
        return len(args[0])

    def string_rep(self, args: list):
        self.index_error('string_rep', args, 2)
        string = args[0]
        rep = args[1]
        if not isinstance(string, str):
            print(f"Error: Bad argument to 'rep' (string expected, got {type(string)})")
            exit(True)
        if isinstance(rep, int):
            return string * rep
        else:
            print(f"Error: Bad argument to 'rep' (number expected, got {type(rep)})")
            exit(True)

    def string_sub(self, args: list):
        self.index_error('string_sub', args, 2)
        string = args[0]
        start = args[1]
        end =  args[2] if len(args) == 3 else None
        if not isinstance(string, str):
            print(f"Error: Bad argument to 'sub' (string expected, got {type(string)})")
            exit(True)
        if isinstance(start, int) and (isinstance(end, int) or end == None): 
            if not end:
                return string[start - 1:]
            return string[start - 1:end]
        else:
            print(f"Error: Bad argument to 'sub' (number expected, got {type(start), type(end)})")
            exit(True)

    def table_insert(self, args: list):
        self.index_error('table_insert', args, 2)
        table = args[0]
        val = args[1]

        if not isinstance(table, dict):
            print(f"Error: Bad argument to 'table_insert' (dict expected, got {type(table)})")
            exit(True)
        table[len(table) + 1] = val
        return table

    def table_remove(self, args: list):
        self.index_error('table_remove', args, 2)
        table = args[0]
        key = args[1]

        if not isinstance(table, dict):
            print(f"Error: Bad argument to 'table_remove' (dict expected, got {type(table)})")
            exit(True)
        if key in table:
            del table[key]
        return table

    def assert_error(self, args: list):
        return

    def io_read(self, args: list):
        return

    def io_write(self, args: list):
        return

    def os_exit(self, args: list):
        return

    def all(self):
        return {
            "print": self.print,
            "tonumber": self.tonumber,
            "tostring": self.tostring,
            "type": self.type,
            "string_byte": self.string_byte,
            "string_len": self.string_len,
            "string_rep": self.string_rep,
            "string_sub": self.string_sub,
            "table_insert": self.table_insert,
            "table_remove": self.table_remove,
            "assert": self.assert_error,
            "io_read": self.io_read,
            "io_write": self.io_write,
            "os_exit": self.os_exit
        }


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
    variables = FunçaoInterna().all()  # variáveis globais

    for line in prog:
        instruction = line.split()[0]

        if instruction == 'NUMBER':
            stack.push_stack(int(line.split()[1]))

        elif instruction == 'NIL':
            stack.push_stack(None)

        elif instruction == 'NEG':
            n1 = stack.pop_stack()
            if type(n1) != int:
                print(f"TypeError: unsupported operand type(s) for {instruction}: 'int' and {type(n1)}")
                exit(True)
            stack.push_stack(calc_exp(n1, None, instruction))

        elif instruction == 'STRING':
            string = re.findall(r'"([^"\\]*(?:\\.[^"\\]*)*)"', line)[0]
            string = string.replace("@n", "\n").replace("@r", "\r").replace("@@", "@")  # add aqui o @q
            stack.push_stack(str(string))

        elif instruction == 'SET_GLOBAL':
            var = stack.pop_stack()
            variables[line.split()[1]] = var

        elif instruction == 'GET_GLOBAL':
            try:
                val = variables[line.split()[1]]
            except:
                val = None
            stack.push_stack(val)

        elif instruction == 'NEW_TABLE':
            newtable = {}
            for _ in range(int(line.split()[1])):
                val = stack.pop_stack()
                key = stack.pop_stack()
                newtable[key] = val 
            # inverte a ordem dos itens para que o dict seja exatamente igual à tabela em lua
            newtable = dict(list(newtable.items())[::-1])
            stack.push_stack(newtable)

        elif instruction == 'EXIT':
            break

        elif instruction == 'CALL':
            n_args = int(line.split()[1])
            args = []
            for _ in range(n_args):
                n1 = stack.pop_stack()
                args.append(n1)
            args = args[::-1]

            func = stack.pop_stack()
            if not func:
                print(f"Error: The passed function doesn't exist.")
                exit(True)
            stack.push_stack(func(args))

        elif instruction == 'POP':
            for _ in range(int(line.split()[1])):
                stack.pop_stack()

        elif instruction in ['ADD', 'SUB', 'MUL', 'IDIV', 'MOD']:
            n1 = stack.pop_stack()
            n2 = stack.pop_stack()
            if type(n1) != int or type(n2) != int:
                print(f"TypeError: unsupported operand type(s) for {instruction}: {type(n1)} and {type(n1)}")
                exit(True)
            stack.push_stack(calc_exp(n1, n2, instruction))

        elif instruction == 'LEN':
            n1 = stack.pop_stack()
            if type(n1) not in (str, dict):
                print(f"TypeError: object of type {type(n1)} has no LEN.")
                exit(True)

            if type(n1) == str:  # len de strings
                stack.push_stack(len(n1))
            else:  # len de tabelas
                len_items = 0
                for item in n1.values():
                    if not item: break
                    len_items += 1
                stack.push_stack(len_items)

        elif instruction == 'CONCAT':
            n1 = stack.pop_stack()
            n2 = stack.pop_stack()
            if type(n1) not in (str, int) or type(n2) not in (str, int):
                print(f"TypeError: unsupported operand type(s) for {instruction}: {type(n1)} and {type(n1)}")
                exit(True)
            str_concat = str(n2)+str(n1)
            stack.push_stack(str_concat)

        else:
            print(f"Error: the instruction {instruction} doesn't exists.")
            exit(True)


#---------------------------------------------- EXECUÇÃO DO PROGRAMA ---------------------------------------

prog = list_instructions()
eval(prog)
