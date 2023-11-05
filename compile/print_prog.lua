local print_prog =  {}

--[[Função auxiliar para gerar espaços de identação]]
function indentation (i) return string.rep(" ", i) end


-- 
function print_prog.printProg(e, indent)
    --[=[
    Imprime na tela a árvore gerada pelo analisador sintático.
    ]=]
    indent = indent or 0

    if e.tag == 'Prog' then
        print(indentation(indent)..e.tag)
        print_prog.printProg(e.bloco, indent+2)
        return

    elseif e.tag == 'Bloco' then
        print(indentation(indent)..e.tag)
        for _, v in pairs(e.block) do
            print_prog.printProg(v, indent+2)
        end
        return

    elseif e.tag == 'CmdDo' then
        print(indentation(indent)..e.tag)
        print_prog.printProg(e.bloco, indent+2)
        return

    elseif e.tag == 'CmdWhile' then
        print(indentation(indent)..e.tag)
        print_prog.printProg(e.exp, indent+2)
        print_prog.printProg(e.bloco, indent+2)
        return

    elseif e.tag == 'CmdIfElse' then
        print(indentation(indent)..e.tag)
        print_prog.printProg(e.exp, indent+2)
        print_prog.printProg(e.bloco, indent+2)
        print_prog.printProg(e.elses, indent+2)
        return

    elseif e.tag == 'CmdLocal' then
        print(indentation(indent)..e.tag)
        print_prog.printProg(e.name, indent+2)
        print_prog.printProg(e.exp, indent+2)
        return

    elseif e.tag == 'CmdFunction' then
        print(indentation(indent)..e.tag)
        print_prog.printProg(e.name, indent+2)
        print_prog.printProg(e.params, indent+2)
        print_prog.printProg(e.bloco, indent+2)
        return

    elseif e.tag == 'CmdReturn' then
        print(indentation(indent)..e.tag)
        print_prog.printProg(e.exp, indent+2)
        return

    elseif e.tag == 'CmdAtribui' then
        print(indentation(indent)..e.tag)
        print_prog.printProg(e.name, indent+2)
        print_prog.printProg(e.exp, indent+2)
        return

    elseif e.tag == 'CmdChamada' then
        print(indentation(indent)..e.tag)
        print_prog.printProg(e.exp, indent+2)
        return

    elseif e.tag == 'ExpUn' then
        print(indentation(indent)..e.tag.." "..e.op)
        print_prog.printProg(e.exp, indent+2)
        return

    elseif e.tag == 'ExpBin' then
        print(indentation(indent)..e.tag.." "..e.op)
        print_prog.printProg(e.e1, indent+2)
        print_prog.printProg(e.e2, indent+2)
        return

    elseif e.tag == 'ExpIndice' then
        print(indentation(indent)..e.tag)
        print_prog.printProg(e.e, indent+2)
        return

    elseif e.tag == 'ExpChamada' then
        print(indentation(indent)..e.tag)
        print_prog.printProg(e.e, indent+2)
        return

    elseif e.tag == 'ExpNil' then
        print(indentation(indent)..e.tag)
        return

    elseif e.tag == 'ExpBool' then
        print(indentation(indent)..e.tag.." "..e.val)
        return

    elseif e.tag == 'ExpNum' then
        print(indentation(indent)..e.tag.." "..e.val)
        return

    elseif e.tag == 'ExpStr' then
        print(indentation(indent)..e.tag.." "..e.val)
        return

    elseif e.tag == 'ExpNome' then
        print(indentation(indent)..e.tag.." "..e.val)
        return

    elseif e.tag == 'ExpTabela' then
        print(indentation(indent)..e.tag)
        for _, v in pairs(e.keyvals) do
            print_prog.printProg(v, indent+2)
        end
        return

    elseif e.tag == 'KeyVal' then
        print(indentation(indent)..e.tag)
        print_prog.printProg(e.key, indent+2)
        print_prog.printProg(e.val, indent+2)
        return

    elseif e.tag == 'Params' then
        print(indentation(indent)..e.tag)
        for _, v in pairs(e.params) do
            print_prog.printProg(v, indent+2)
        end
        return

    elseif e.tag == 'Exps' then
        print(indentation(indent)..e.tag)
        for _, v in pairs(e.exps) do
            print_prog.printProg(v, indent+2)
        end
        return

    else
        assert(false, "\nThe expression or command isn't mapped here.\n")
    end
end


return print_prog
