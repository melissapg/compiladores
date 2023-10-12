-- função auxiliar para criar 1 espaço de identação
function indentation (i) return string.rep(" ", i) end


-- printa a árvore com identação
function printProg(e, indent)
    indent = indent or 0
    if e.tag == 'Prog' then
        print(indentation(indent)..e.tag)
        printProg(e.bloco, indent+2)
        return
    elseif e.tag == 'Bloco' then
        print(indentation(indent)..e.tag)
        for _, v in pairs(e.block) do
            printProg(v, indent+2)
        end
        return
    elseif e.tag == 'CmdDo' then
        print(indentation(indent)..e.tag)
        printProg(e.bloco, indent+2)
        return
    elseif e.tag == 'CmdWhile' then
        print(indentation(indent)..e.tag)
        printProg(e.exp, indent+2)
        printProg(e.bloco, indent+2)
        return
    elseif e.tag == 'CmdIfElse' then
        print(indentation(indent)..e.tag)
        printProg(e.exp, indent+2)
        printProg(e.bloco, indent+2)
        printProg(e.elses, indent+2)
        return
    elseif e.tag == 'CmdLocal' then
        print(indentation(indent)..e.tag)
        printProg(e.name, indent+2)
        printProg(e.exp, indent+2)
        return
    elseif e.tag == 'CmdFunction' then
        print(indentation(indent)..e.tag)
        printProg(e.name, indent+2)  -- bom acho que o erro ta nisso aqui
        printProg(e.params, indent+2)
        printProg(e.bloco, indent+2)
        return
    elseif e.tag == 'CmdReturn' then
        print(indentation(indent)..e.tag)
        printProg(e.exp, indent+2)
        return 
    elseif e.tag == 'CmdAtribui' then
        print(indentation(indent)..e.tag)
        printProg(e.name, indent+2)
        printProg(e.exp, indent+2)
        return
    elseif e.tag == 'CmdChamada' then
        print(indentation(indent)..e.tag)
        printProg(e.exp, indent+2)
        return
    elseif e.tag == 'ExpUn' then  -- isso aqui tá rodando toda vida até a eternidade quando tá em NOT, parentenses...
        print(indentation(indent)..e.tag.." "..e.op)
        printProg(e.exp, indent+2)
        return
    elseif e.tag == 'ExpBin' then
        print(indentation(indent)..e.tag.." "..e.op)
        printProg(e.e1, indent+2)
        printProg(e.e2, indent+2)
        return
    elseif e.tag == 'ExpIndice' then  -- cade o primeiro nome do indice ??? erro
        print(indentation(indent)..e.tag)
        printProg(e.e, indent+2)
        return
    elseif e.tag == 'ExpChamada' then  -- cade o nome da função que tá sendo chamada ??? erro
        print(indentation(indent)..e.tag)
        printProg(e.e, indent+2)
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
    elseif e.tag == 'ExpTabela' then  -- erro nas tabelas com mais de um key, val
        print(indentation(indent)..e.tag)
        for _, v in pairs(e.keyvals) do
            printProg(v, indent+2)
        end
        return
    elseif e.tag == 'KeyVal' then
        print(indentation(indent)..e.tag)  -- ajustar aqui
        printProg(e.key, indent+2)
        printProg(e.val, indent+2)
        return
    elseif e.tag == 'Params' then
        print(indentation(indent)..e.tag)
        for _, v in pairs(e.params) do
            printProg(v, indent+2)
        end
        return
    elseif e.tag == 'Exps' then
        print(indentation(indent)..e.tag)
        for _, v in pairs(e.exps) do
            printProg(v, indent+2)
        end
        return
    else
        for k, v in pairs(e) do
            print(k, v)
        end
        assert(false)
    end
end
