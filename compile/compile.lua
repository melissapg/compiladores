parser = require("parser")  -- modulo parser


function add_instr(instruction, val)
  program_counter = program_counter + 1
  table.insert(instructions, {instr = instruction, val = val})
end


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
    compileJumpTrue(exp.exp, dest)
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


function create_variable(name)
  locals_counter = locals_counter + 1
  table.insert(locals, {name = name})
  return locals_counter
end


function find_variable(name)
  local len_locals = locals_counter
  while len_locals > 0 do
    if name == locals[len_locals].name then
      return len_locals
    end
    len_locals =  len_locals - 1
  end
  return nil
end


function enter_scope()
  scopes_counter = scopes_counter + 1
  table.insert(scopes, locals_counter)
end


function exit_scope()
  --[[
  Pop em todas as variáveis locais do escopo que está saindo.
  ]]
  while locals_counter > scopes[scopes_counter] do
    table.remove(locals, locals_counter)
    locals_counter = locals_counter - 1
  end
  table.remove(scopes, scopes_counter)
  scopes_counter = scopes_counter - 1
end


function compile_prog(e)
  if e.tag == 'Prog' then
    compile_prog(e.bloco)
    return

  elseif e.tag == 'Bloco' then
    local i = 1
    while i <= #e.block do
      compile_prog(e.block[i])
      i = i + 1
    end
    return
  elseif e.tag == 'CmdWhile' then
    enter_scope()
    local lbl_cond = new_label()
    fix_label(lbl_cond)
    local lbl_fim = new_label()
    compileJumpFalse(e.exp, lbl_fim)
    compile_prog(e.bloco)
    add_instr("JUMP", lbl_cond)
    fix_label(lbl_fim)
    exit_scope()
    return
  elseif e.tag == 'CmdIfElse' then
    enter_scope()
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
    exit_scope()
    return
  elseif e.tag == 'CmdLocal' then
    local id = create_variable(e.name.val)
    if e.exp then
      compile_prog(e.exp)
    else
      add_instr("NIL")
    end
    add_instr("SET_LOCAL", id)
    return
  elseif e.tag == 'CmdFunction' then
    enter_scope()
    local func_name = e.name.val
    local cont_params = 0
    local i = 1
    local params_exist = true
    while params_exist do
      if not e.params.params[i] then
        params_exist = false
      else
        create_variable(e.params.params[i].val)
        cont_params = cont_params + 1
        i = i + 1
      end
    end
    add_instr("FUNCTION "..func_name, cont_params)
    compile_prog(e.bloco)
    exit_scope()
    add_instr("NIL")
    add_instr("RETURN")
    return
  elseif e.tag == 'CmdReturn' then
    if not e.exp then
      add_instr("NIL")
      add_instr("RETURN")
    else
      compile_prog(e.exp)
      add_instr("RETURN")
    end
    return
  elseif e.tag == 'CmdAtribui' then
    if e.name.tag == 'ExpNome' then
      compile_prog(e.exp)
      local is_local = find_variable(e.name.val)
      if is_local ~= nil then
        add_instr("SET_LOCAL", is_local)
      else
        add_instr("SET_GLOBAL", e.name.val)
      end
    elseif e.name.tag == 'ExpIndice' then
      compile_prog(e.name.table)
      -- Uma tabela x tem como índice um y qualquer, que é representado como uma string. (x.y <=> x["y"]) 
      if e.name.e.tag == 'ExpNome' then
        e.name.e.tag = 'ExpStr'
      end
      compile_prog(e.name.e)
      compile_prog(e.exp)
      add_instr("SET_TABLE")
    end
    return
  elseif e.tag == 'CmdChamada' then
    compile_prog(e.exp)
    add_instr("POP", 1)
    return

  elseif e.tag == 'ExpBin' and e.op == '+' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("ADD")
    return
  elseif e.tag == 'ExpBin' and e.op == '-' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("SUB")
    return
  elseif e.tag == 'ExpBin' and e.op == '/' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("IDIV")
    return
  elseif e.tag == 'ExpBin' and e.op == '*' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("MUL")
    return
  elseif e.tag == 'ExpBin' and e.op == '%' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("MOD")
    return
  elseif e.tag == 'ExpBin' and e.op == '..' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("CONCAT")
    return

  elseif e.tag == 'ExpUn' and e.op == '-' then
    compile_prog(e.exp)
    add_instr("NEG")
    return
  
  elseif e.tag == 'ExpUn' and e.op == '#' then
    compile_prog(e.exp)
    add_instr("LEN")
    return
  elseif e.tag == 'ExpBin' and e.op == '==' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("EQ")
    return
  elseif e.tag == 'ExpBin' and e.op =='~=' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("NEQ")
    return
  elseif e.tag == 'ExpBin' and e.op =='<' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("LT")
    return
  elseif e.tag == 'ExpBin' and e.op =='<=' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("LE")
    return
  elseif e.tag == 'ExpBin' and e.op =='>' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("GT")
    return
  elseif e.tag == 'ExpBin' and e.op =='>=' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    add_instr("GE")

  elseif e.tag == 'ExpNil' then
    add_instr("NIL")
    return
  elseif e.tag == 'ExpBool' then
    if e.val == true then
      add_instr("BOOL", "true")
    else
      add_instr("BOOL", "false")
    end
    return
  elseif e.tag == 'ExpNum' then
    add_instr("NUMBER", e.val)
    return
  elseif e.tag == 'ExpStr' then
    local pos = 1
    local word = ''
    local loop_condition = true
    while loop_condition do
      char = string.sub(e.val, pos, pos)
      if char == '\n' then
        char = '@n'
      elseif char == '\r' then
        char = '@r'
      elseif char == '@' then
        char = '@@'
      end
      word = word .. char
      if pos == #e.val then
        loop_condition = false
      else
        pos = pos + 1
      end
    end
    add_instr('STRING "'..word..'"')
    return
  elseif e.tag == 'ExpNome' then
    local is_local = find_variable(e.val)
    if is_local ~= nil then
      add_instr("GET_LOCAL", is_local)
    else
      add_instr("GET_GLOBAL", e.val)
    end
    return

  elseif e.tag == 'ExpIndice' then
    compile_prog(e.table)
    -- Uma tabela x tem como índice um y qualquer, que é representado como uma string. (x.y <=> x["y"]) 
    if e.e.tag == 'ExpNome' then
      e.e.tag = 'ExpStr'
    end
    compile_prog(e.e)
    add_instr("GET_TABLE")
    return

  elseif e.tag == 'ExpChamada' then
    compile_prog(e.func)
    compile_prog(e.e)
    return
  elseif e.tag == 'Exps' then
    local exps = 0
    local i = 1
    while i <= #e.exps do
      compile_prog(e.exps[i])
      exps = exps + 1
      i = i + 1
    end
    add_instr("CALL", exps)
    return

  elseif e.tag == 'ExpTabela' then
    local keys = 0
    local i = 1
    while i <= #e.keyvals do
      compile_prog(e.keyvals[i])
      keys = keys + 1
      i = i + 1
    end
    add_instr("NEW_TABLE", keys)
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


function main()
  texto = io.read("a")

  parser.init_parser(texto)
  prog = parser.parseProg()

  instructions = {}  -- armazena as instruções
  program_counter = 0  -- contador de instruções

  labels = {}  -- armazena as labels
  labels_counter = 0  -- contador de labels

  locals = {}  -- armazena as variáveis locais
  locals_counter = 0  -- contador de variáveis locais

  scopes = {}  -- armazena os escopos
  scopes_counter = 0  -- contador de escopos

  compile_prog(prog)
  print_prog()
  print("EXIT")
end


main()
