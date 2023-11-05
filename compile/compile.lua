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

  elseif e.tag == 'CmdAtribui' then
    compile_prog(e.exp)
    print("SETGLOBAL "..e.name.val)
    return

  elseif e.tag == 'CmdReturn' then
    compile_prog(e.exp)
    print("RETURN")
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
    print("DIV")
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

  elseif e.tag == 'ExpUn' and e.op == '-' then
    compile_prog(e.exp)
    print("NEG")
    return

  elseif e.tag == 'ExpNum' then
    print("NUMBER "..e.val)
    return

  elseif e.tag == 'ExpNome' then
    print("GETGLOBAL "..e.val)
    return

  else
    assert(false)
  end
end

compile_prog(prog)
