parser = require("parser")  -- modulo parser

texto = io.read("a")

parser.init_parser(texto)
prog = parser.parseProg()


function compile_prog(e)
  if e.tag == 'Prog' then
    compile_prog(e.bloco)
    return

  elseif e.tag == 'Bloco' then
    for _, v in pairs(e.block) do
      compile_prog(v)
    end
    return
  elseif e.tag == 'CmdReturn' then
    compile_prog(e.exp)
    print("RETURN")
    return
  elseif e.tag == 'CmdAtribui' then
    if e.name.tag == 'ExpNome' then
      compile_prog(e.exp)
      print("SET_GLOBAL "..e.name.val)
    elseif e.name.tag == 'ExpIndice' then
      compile_prog(e.name)
      compile_prog(e.exp)
      print("SET_TABLE")
    end
    return
  elseif e.tag == 'CmdChamada' then
    compile_prog(e.exp)
    print("POP "..1)
    return

  elseif e.tag == 'ExpBin' and e.op == '+' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    print("ADD")
    return
  elseif e.tag == 'ExpBin' and e.op == '-' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    print("SUB")
    return
  elseif e.tag == 'ExpBin' and e.op == '/' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    print("IDIV")
    return
  elseif e.tag == 'ExpBin' and e.op == '*' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    print("MUL")
    return
  elseif e.tag == 'ExpBin' and e.op == '%' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    print("MOD")
    return
  elseif e.tag == 'ExpBin' and e.op == '..' then
    compile_prog(e.e1)
    compile_prog(e.e2)
    print("CONCAT")
    return

  elseif e.tag == 'ExpUn' and e.op == '-' then
    compile_prog(e.exp)
    print("NEG")
    return
  
  elseif e.tag == 'ExpUn' and e.op == '#' then
    compile_prog(e.exp)
    print("LEN")
    return

  elseif e.tag == 'ExpNil' then
    print("NIL")
    return
  elseif e.tag == 'ExpNum' then
    print("NUMBER "..e.val)
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
    print('STRING "'..word..'"')
    return
  elseif e.tag == 'ExpNome' then
    print("GET_GLOBAL "..e.val)
    return

  elseif e.tag == 'ExpIndice' then
    compile_prog(e.table)
    -- Uma tabela x tem como índice um y qualquer, que é representado como uma string. (x.y <=> x["y"]) 
    if e.e.tag == 'ExpNome' then
      e.e.tag = 'ExpStr'
    end
    compile_prog(e.e)
    print("GET_TABLE")
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
    print("CALL "..exps)
    return

  elseif e.tag == 'ExpTabela' then
    local keys = 0
    for _, v in pairs(e.keyvals) do
      compile_prog(v)
      keys = keys + 1
    end
    print("NEW_TABLE "..keys)
    return
  elseif e.tag == 'KeyVal' then
    compile_prog(e.key)
    compile_prog(e.val)
    return

  else
    assert(false)
  end
end

compile_prog(prog)
print("EXIT")