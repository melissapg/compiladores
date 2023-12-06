parser = require("parser")  -- modulo parser

texto = io.read("a")

parser.init_parser(texto)
prog = parser.parseProg()


instructions = {}  -- armazena as instruções
program_counter = 0  -- contador de instruções
function add_instr(instruction, val)
  program_counter = program_counter + 1
  table.insert(instructions, {instr = instruction, val = val})
end


labels = {}
labels_counter = 0
function new_label()
  labels_counter = labels_counter + 1
  local lbl_id = 'l'..labels_counter
  labels[lbl_id] = { val = nil }
  return lbl_id
end


function fix_label(lbl)
  labels[lbl].val = program_counter
end


function compileJumpFalse(exp, dest)
  if exp.op == 'not' then
    compileJumpTrue(exp, dest)
  elseif exp.op == 'and' then
    compileJumpFalse(exp.e1, dest)
    compileJumpFalse(exp.e2, dest)
  elseif exp.op == 'or' then
    local lbl_fim_exp = new_label()
    compileJumpTrue(exp.e1, lbl_fim_exp)
    compileJumpFalse(exp.e2, dest)
    fix_label(lbl_fim_exp)
  else
    compile_prog(exp)
    add_instr("JUMP_FALSE", dest)
  end
end


function compileJumpTrue(exp, dest)
  if exp.op == 'not' then
    compileJumpTrue(exp, dest)
  elseif exp.op == 'and' then
    compileJumpFalse(exp.e1, dest)
    compileJumpFalse(exp.e2, dest)
  elseif exp.op == 'or' then
    local lbl_fim_exp = new_label()
    compileJumpTrue(exp.e1, lbl_fim_exp)
    compileJumpFalse(exp.e2, dest)
    fix_label(lbl_fim_exp)
  else
    compile_prog(exp)
    add_instr("JUMP_TRUE", dest)
  end
end


function compile_prog(e)
  if e.tag == 'Prog' then
    compile_prog(e.bloco)
    return

  elseif e.tag == 'Bloco' then
    for _, v in pairs(e.block) do
      compile_prog(v)
    end
    return
  elseif e.tag == 'CmdIfElse' then
    local lbl_else = new_label()
    local lbl_fim = new_label()
    compileJumpFalse(e.exp, lbl_else)
    compile_prog(e.bloco)
    add_instr("JUMP", lbl_fim)
    fix_label(lbl_else)
    if e.elses then
      compile_prog(e.elses)
    end
    fix_label(lbl_fim)
    return
  elseif e.tag == 'CmdReturn' then
    compile_prog(e.exp)
    add_instr("RETURN")
    -- print("RETURN")
    return
  elseif e.tag == 'CmdAtribui' then
    if e.name.tag == 'ExpNome' then
      compile_prog(e.exp)
      add_instr("SET_GLOBAL", e.name.val)
      -- print("SET_GLOBAL "..e.name.val)
    elseif e.name.tag == 'ExpIndice' then
      compile_prog(e.name.table)
      -- Uma tabela x tem como índice um y qualquer, que é representado como uma string. (x.y <=> x["y"]) 
      if e.name.e.tag == 'ExpNome' then
        e.name.e.tag = 'ExpStr'
      end
      compile_prog(e.name.e)
      compile_prog(e.exp)
      add_instr("SET_TABLE")
      -- print("SET_TABLE")
    end
    return
  elseif e.tag == 'CmdChamada' then
    compile_prog(e.exp)
    add_instr("POP", 1)
    -- print("POP "..1)
    return

  elseif e.tag == 'ExpBin' and e.op == '+' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("ADD")
    -- print("ADD")
    return
  elseif e.tag == 'ExpBin' and e.op == '-' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("SUB")
    -- print("SUB")
    return
  elseif e.tag == 'ExpBin' and e.op == '/' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("IDIV")
    -- print("IDIV")
    return
  elseif e.tag == 'ExpBin' and e.op == '*' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("MUL")
    -- print("MUL")
    return
  elseif e.tag == 'ExpBin' and e.op == '%' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("MOD")
    -- print("MOD")
    return
  elseif e.tag == 'ExpBin' and e.op == '..' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("CONCAT")
    -- print("CONCAT")
    return

  elseif e.tag == 'ExpUn' and e.op == '-' then
    compile_prog(e.exp)
    add_instr("NEG")
    -- print("NEG")
    return
  
  elseif e.tag == 'ExpUn' and e.op == '#' then
    compile_prog(e.exp)
    add_instr("LEN")
    -- print("LEN")
    return
  elseif e.tag == 'ExpBin' and e.op == '==' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("EQ")
    -- print("EQ")
    return
  elseif e.tag == 'ExpBin' and e.op =='~=' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("NEQ")
    -- print("NEQ")
    return
  elseif e.tag == 'ExpBin' and e.op =='<' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("LT")
    -- print("LT")
    return
  elseif e.tag == 'ExpBin' and e.op =='<=' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("LE")
    -- print("LE")
    return
  elseif e.tag == 'ExpBin' and e.op =='>' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("GT")
    -- print("GT")
    return
  elseif e.tag == 'ExpBin' and e.op =='>=' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("GE")
    -- print("GE")

  elseif e.tag == 'ExpNil' then
    add_instr("NIL")
    -- print("NIL")
    return
  elseif e.tag == 'ExpBool' then
    if e.val == true then
      add_instr("BOOL", "true")
      -- print("BOOL ".."true")
    else
      add_instr("BOOL", "false")
      -- print("BOOL ".."false")
    end
    return
  elseif e.tag == 'ExpNum' then
    add_instr("NUMBER", e.val)
    -- print("NUMBER "..e.val)
    return
  elseif e.tag == 'ExpStr' then
    local pos = 1
    local word = ''
    while true do
      char = string.sub(e.val, pos, pos)
      if char == '\n' then
        char = '@n'
      elseif  char == '\r'  then
        char = '@r'
      elseif  char == '@'  then
        char = '@@'
      -- elseif  char == '"' or "'" then  # consertar aqui add o @q
      --   char = '@q'
      end
      word = word..char
      if pos == #e.val then break end
      pos = pos + 1
    end
    add_instr('STRING "'..word..'"')
    -- print('STRING "'..word..'"')
    return
  elseif e.tag == 'ExpNome' then
    add_instr("GET_GLOBAL", e.val)
    -- print("GET_GLOBAL "..e.val)
    return

  elseif e.tag == 'ExpIndice' then
    compile_prog(e.table)
    -- Uma tabela x tem como índice um y qualquer, que é representado como uma string. (x.y <=> x["y"]) 
    if e.e.tag == 'ExpNome' then
      e.e.tag = 'ExpStr'
    end
    compile_prog(e.e)
    add_instr("GET_TABLE")
    -- print("GET_TABLE")
    return

  elseif e.tag == 'ExpChamada' then
    compile_prog(e.func)
    compile_prog(e.e)
    return
  elseif e.tag == 'Exps' then
    local exps = 0
    for _, v in pairs(e.exps) do
      compile_prog(v)
      exps = exps + 1
    end
    add_instr("CALL", exps)
    -- print("CALL "..exps)
    return

  elseif e.tag == 'ExpTabela' then
    local keys = 0
    for _, v in pairs(e.keyvals) do
      compile_prog(v)
      keys = keys + 1
    end
    add_instr("NEW_TABLE", keys)
    -- print("NEW_TABLE "..keys)
    return
  elseif e.tag == 'KeyVal' then
    compile_prog(e.key)
    compile_prog(e.val)
    return

  else
    assert(false)
  end
end


function print_prog()
  local idx = 1
  while idx < #instructions + 1 do
    local instr = instructions[idx]['instr']
    local val = instructions[idx]['val']
    if val then
      if string.sub(val, 1, 1) == 'l' then
        local label = labels[val].val
        print(instr..' '..label)
      else
        print(instr..' '..val)
      end
    else print(instr) end
    idx = idx + 1
  end
end


compile_prog(prog)
print_prog()
print("EXIT")
