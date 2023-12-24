import sys
import re


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


MODULAR_FUNCTIONS = ['byte', 'len', 'rep', 'sub', 'insert', 'remove']
class FunçaoInterna:
    def index_error(self, function_name: str, args: list, n_args: int = 1):
        more_args = f' or {n_args}' if n_args != 1 else ''
        if len(args) < n_args:
            print(f"TypeError: {function_name}() takes 1{more_args} argument(s).")
            exit(True)

    def print(self, args: list, out: str = ''):
        out = '\t'.join(str(arg) for arg in args)
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

    # string module
    def byte(self, args: list):
        self.index_error('string.byte', args, 1)

        string = args[0]
        idx = 1 if len(args) < 2 else args[1]
        if not isinstance(string, str):
            print(f"Error: Bad argument to 'byte' (string expected, got {type(string)})")
            exit(True)
        if idx >= 1 and idx <= len(string) and isinstance(idx, int):
            return ord(string[idx - 1])
        else:
            return None

    # string module
    def len(self, args: list):
        self.index_error('string.len', args)
        if not isinstance(args[0], str):
            print(f"Error: Bad argument to 'len' (string expected, got {type(args[0])})")
            exit(True)
        return len(args[0])

    # string module
    def rep(self, args: list):
        self.index_error('string.rep', args, 2)
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

    # string module
    def sub(self, args: list):
        self.index_error('string.sub', args, 2)
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

    def insert(self, args: list):
        self.index_error('table.insert', args, 2)
        table = args[0]
        val = args[1]

        if not isinstance(table, dict):
            print(f"Error: Bad argument to 'insert' (dict expected, got {type(table)})")
            exit(True)
        table[len(table) + 1] = val
        return table

    def remove(self, args: list):
        self.index_error('table.remove', args, 2)
        table = args[0]
        key = args[1]

        if not isinstance(table, dict):
            print(f"Error: Bad argument to 'remove' (dict expected, got {type(table)})")
            exit(True)
        if key in table:
            del table[key]
        return table

    def all(self):
        return {
            "print": self.print,
            "tonumber": self.tonumber,
            "tostring": self.tostring,
            "type": self.type,
            "string": {
                "byte": self.byte,
                "len": self.len,
                "rep": self.rep,
                "sub": self.sub
            },
            "table": {
                "insert": self.insert,
                "remove": self.remove
            }
        }


class FuncaoExterna:
    def __init__(self):
        self.functions = {}

    def add_function(self, name, n_args, address):
        self.functions[name] = {"address": address + 1,
                                "n_args": n_args}

    def find_function(self, name):
        # ver o que realmente precisa add aqui, CALL
        if name in self.functions:
            return self.functions[name]
        else:
            return False


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
        args = []
        instrs = line.split()
        if instrs[0] == 'STRING':
            args.append(instrs[0])
            args.append(re.findall(r'"([^"\\]*(?:\\.[^"\\]*)*)"', line)[0])
        else:
            args = [arg for arg in instrs]
        prog_array.append(args)
    return prog_array


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


def get_bool(n1, n2, op):
    if op == 'EQ':
        return n2 == n1
    elif op == 'NEQ':
        return n2 != n1
    elif op == 'LT':
        return n2 < n1
    elif op == 'LE':
        return n2 <= n1
    elif op == 'GT':
        return n2 > n1
    elif op == 'GE':
        return n2 >= n1
    else:
        print(f"Error: exp operation {op} doesn't exist.")
        exit(True)


def eval(prog):
    stack = Stack()
    variables = FunçaoInterna().all()  # variáveis globais
    functions = FuncaoExterna()  # funções externas
    program_counter = 0

    saved_stack = stack
    saved_pc = program_counter

    while True:
        line = prog[program_counter]
        instruction = line[0]

        if instruction == 'NUMBER':
            stack.push_stack(int(line[1]))

        elif instruction == 'NIL':
            stack.push_stack(None)

        elif instruction == 'BOOL':
            bool_t = line[1]
            if bool_t == 'true':
                bool_t = True
            else:
                bool_t = False
            stack.push_stack(bool_t)

        elif instruction == 'NEG':
            n1 = stack.pop_stack()
            if type(n1) != int:
                print(f"TypeError: unsupported operand type(s) for {instruction}: 'int' and {type(n1)}")
                exit(True)
            stack.push_stack(calc_exp(n1, None, instruction))

        elif instruction == 'STRING':
            string = line[1]

            replacements = {"@n": "\n", "@r": "\r", "@@": "@"}
            for pattern, replacement in replacements.items():
                string = re.sub(re.escape(pattern), replacement, string)
            stack.push_stack(str(string))

        elif instruction == 'SET_GLOBAL':
            var = stack.pop_stack()
            variables[line[1]] = var

        elif instruction == 'GET_GLOBAL':
            if line[1] in MODULAR_FUNCTIONS:
                functions = stack.pop_stack()
                stack.push_stack(functions[line[1]])
            else:
                try:
                    val = variables[line[1]]
                except:
                    try:
                        val = functions.find_function(line[1])
                    except:
                        val = None
                stack.push_stack(val)

        elif instruction == 'SET_LOCAL':
            var = stack.pop_stack()
            variables[int(line[1])] = var

        elif instruction == 'GET_LOCAL':
            try:
                val = variables[int(line[1])]
            except:
                val = None
            stack.push_stack(val)

        elif instruction == 'NEW_TABLE':
            newtable = {}
            for _ in range(int(line[1])):
                val = stack.pop_stack()
                key = stack.pop_stack()
                newtable[key] = val
            # inverte a ordem dos itens para que o dict seja exatamente igual à tabela em lua
            newtable = dict(list(newtable.items())[::-1])
            stack.push_stack(newtable)
        
        elif instruction == 'GET_TABLE':
            if prog[program_counter+1][0] == 'CALL':
                program_counter += 1
                continue
            key = stack.pop_stack()
            table = stack.pop_stack()
            if not isinstance(table, dict):
                print(f"Error: Table {table} is not defined.")
                exit(True)
            try:
                val = table[key]
            except (KeyError, TypeError):  # se a chave não estiver presente, produz nil
                val = None
            stack.push_stack(val)

        elif instruction == 'SET_TABLE':
            val = stack.pop_stack()
            key = stack.pop_stack()
            table = stack.pop_stack()
            if not isinstance(table, dict):
                print(f"Error: Table {table} is not defined.")
                exit(True)
            try:
                table[key] = val
            except (KeyError, TypeError):  # não aceita chave nil
                print(f"Error: Table key must not be None.")
                exit(True)

        elif instruction == 'FUNCTION':
            function_name = line[1]
            n_args = int(line[2])
            functions.add_function(function_name, n_args, program_counter)
            while True:  # dá pra simplificar e melhorar isso aqui
                instruction = prog[program_counter][0]
                program_counter += 1
                next_instruction = prog[program_counter][0]
                if instruction == 'NIL' and next_instruction == "RETURN":
                        break

        elif instruction == 'CALL':
            n_args = int(line[1])
            args = []
            for _ in range(n_args):
                n1 = stack.pop_stack()
                args.append(n1)
            args = args[::-1]

            func = stack.pop_stack()
            if not func:
                print(f"Error: The passed function doesn't exist.")
                exit(True)
            if isinstance(func, dict):
                saved_stack = stack
                saved_pc = program_counter
                stack = Stack()
                for i in range(n_args):
                    stack.push_stack(args[i])
                    variables[i+1] = args[i]

                program_counter = func['address']
                continue
            else:
               stack.push_stack(func(args))

        elif instruction == 'RETURN':
            ret = stack.pop_stack()
            stack = saved_stack
            program_counter = saved_pc
            stack.push_stack(ret)

        elif instruction == 'POP':
            for _ in range(int(line[1])):
                stack.pop_stack()

        elif instruction in ['ADD', 'SUB', 'MUL', 'IDIV', 'MOD']:
            n1 = stack.pop_stack()
            n2 = stack.pop_stack()
            if type(n1) != int or type(n2) != int:
                print(f"TypeError: unsupported operand type(s) for {instruction}: {type(n1)} and {type(n1)}")
                exit(True)
            stack.push_stack(calc_exp(n1, n2, instruction))

        elif instruction in ['EQ', 'NEQ', 'LT', 'LE', 'GT', 'GE']:
            n1 = stack.pop_stack()
            n2 = stack.pop_stack()
            if instruction in ['LT', 'LE', 'GT', 'GE'] and (type(n1) != int or type(n2) != int):
                print(f"TypeError: unsupported operand type(s) for {instruction}: {type(n1)} and {type(n1)}")
                exit(True)

            stack.push_stack(get_bool(n1, n2, instruction))

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

        elif instruction == 'JUMP':
            program_counter = int(line[1])
            continue

        elif instruction == 'JUMP_TRUE':
            bool_t = stack.pop_stack()
            if bool_t:
                program_counter = int(line[1])
                continue

        elif instruction == 'JUMP_FALSE':
            bool_t = stack.pop_stack()
            if not bool_t:
                program_counter = int(line[1])
                continue

        elif instruction == 'EXIT':
            break

        else:
            print(f"Error: the instruction {instruction} doesn't exists.")
            exit(True)

        program_counter += 1


#---------------------------------------------- EXECUÇÃO DO PROGRAMA ---------------------------------------

prog = list_instructions()
eval(prog)
