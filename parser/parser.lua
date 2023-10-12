lexer = require("lexer")


-- melhorar essa função
function syntax_error(msg)
    print("SYNTAX ERROR", msg)
    os.exit(1)
end


local parser =  {}

function parser.init_parser(text)
    lexer.init_lexer(text)
    prox = lexer.get_next_token()
end


function peek(tag)
    -- confere se um token eh o esperado
    -- print(prox.tag == tag, "|", prox.tag)
    return prox.tag == tag
end


function eat(tag)
    -- consome um token e atualiza p/ olhar o proximo
    if prox.value then
        current_tag = prox.value
    else
        current_tag = prox.tag
    end
    if peek(tag) then
        parser.walk()
        return current_tag
    else
        syntax_error("Encontrei um: "..current_tag.." esperava um :"..prox.tag)
    end
end


function parser.walk()
    -- pega o proximo token
    prox = lexer.get_next_token()
    while prox.tag == 'SPACE' or prox.tag == 'COMENTARIO' or prox.tag == 'NEWLINE' do
        prox = lexer.get_next_token()
    end
end


--[[Prog]]
function parser.parseProg()
    print("parseProg")
    local block = parseBlock()
    return {tag = 'Prog', bloco = {tag = "Bloco", block = block}}
end


--[[Cmd]]
function parseCmd()
    print("parseCmd")
    if peek("do") then
        eat("while")
        local block = parseBlock()
        eat("end")
        return {tag = "CmdDo", bloco = {tag = "Bloco", block = block}}

    elseif peek("while") then
        print("CmdWhile")
        eat("while")
        local exp = parseExp()
        eat("do")
        local block = parseBlock()
        eat("end")
        return {tag = "CmdWhile", exp = exp, bloco = {tag = "Bloco", block = block}}

    elseif peek("if") then
        print("CmdIfElse")
        eat("if")
        local exp = parseExp()
        eat("then")
        local block = parseBlock()
        local elses = parseElses()
        return {tag = "CmdIfElse", exp = exp, bloco = {tag = "Bloco", block = block}, elses = elses}

    elseif peek("local") then
        print("CmdLocal")
        eat("local")
        local name = parseExpPrimaria()
        eat("=")
        local exp = parseExp()
        return {tag = 'CmdLocal', name = name, exp = exp}

    elseif peek("function") then
        print("CmdFunction")
        eat("function")
        local name = parseExpPrimaria()
        eat("(")
        local params = Params()
        eat(")")
        local block = parseBlock()
        eat("end")
        return {tag = "CmdFunction", name = name, params = params, bloco = {tag = "Bloco", block = block}}

    elseif peek("return") then
        print("CmdReturn")
        eat("return")
        local exp = parseExp()
        return {tag = "CmdReturn", exp = exp}

    elseif peek("NOME") then
        local exp1 = parseExpSufixada()
        if peek("=") then
            print("CmdAtribui")
            eat("=")
            local exp2 = parseExp()
            return {tag = "CmdAtribui", name = exp1, exp = exp2}
        else
            return {tag = "CmdChamada", exp = exp1}
        end
    else
        syntax_error("Esperava um comando.")
    end
end


--[[Elses]]
function parseElses()
    print("parseElses")
    while not(peek("end")) do
        if peek("else") then
            eat("else")
            local block = parseBlock()
            eat("end")
            return {tag = "Bloco", block = block}
        elseif peek("elseif") then
            eat("elseif")
            local exp = parseExp()
            eat("then")
            local block = parseBlock()
            local elses = parseElses()
            return {tag = "CmdIfElse", exp = exp, bloco = {tag = "Bloco", block = block}, elses = elses}
        else
            syntax_error("Esperava um else ou elseif.")
        end
    end
    eat("end")
    return nil
end


function get_prec(op)
    if op == 'or' then
        return 0
    elseif op == 'and' then
        return 1
    elseif op == '<' or op == '>' or op == '<=' or op == '>=' or op == '==' or op == '~=' then
        return 2
    elseif op == '..' then
        return 3
    elseif op == '+' or op == '-' then
        return 4
    elseif op == '*' or op == '/' or op == '%' then
        return 5
    elseif op == 'not' or op == '#' or op == '-' then
        return 6
    elseif op == '(' or op == '[' then
        return 7
    else
        return nil
    end
end


--[[Exp]]
function parseExp(min_prec)
    print("parseExp")
    min_prec = min_prec or 0

    local e1 = nil
    if peek('#') or peek('-') or peek('not') then
        local op = eat(prox.tag)
        local exp = parseExp(6)
        e1 = {tag = 'ExpUn', op = op, exp = exp}
    else
        e1 = parseExpSimples()
    end

    while get_prec(prox.tag) and get_prec(prox.tag) >= min_prec do
        print("ExpBin")
        local op = eat(prox.tag)
        local e2 = parseExp(min_prec + 1)
        e1 = {tag = 'ExpBin', op = op, e1 = e1, e2 = e2}
    end
    return e1
end


--[[ExpSufixada]]
function parseExpSufixada()
    print("parseExpSufixada")
    local e = parseExpPrimaria()
    while true do
        if peek(".") then
            print("ExpIndice")
            eat(".")
            e = parseExpSufixada()
            return {tag = 'ExpIndice', e = e}
        elseif peek("[") then
            print("ExpIndice")
            eat("[")
            e = parseExp(7)
            eat("]")
            return {tag = 'ExpIndice', e = e}
        elseif peek("(") then
            print("ExpChamada")
            eat("(")
            e = Exps()
            eat(")")
            return {tag = 'ExpChamada', e = e}
        else
            return e
        end
    end
end


--[[ExpSimples]]
function parseExpSimples()
    print("parseExpSimples")
    if peek("nil") then
        print("ExpNil")
        eat("nil")
        return {tag = 'ExpNil', val = nil}
    elseif peek("true") or peek("false") then
        print("ExpBool")
        local bool = eat(prox.tag)
        return {tag = 'ExpBool', val = bool}
    elseif peek("NUMERO") then
        print("ExpNum")
        local number = eat('NUMERO')
        return {tag = 'ExpNum', val = number}
    elseif peek("STRING") then
        print("ExpStr")
        local string = eat("STRING")
        return {tag = 'ExpStr', val = string}
    elseif peek("{") then
        return parseTabela()
    else
        return parseExpSufixada()
    end
end


--[[ExpPrimaria]]
function parseExpPrimaria()
    print("parseExpPrimaria")
    if peek("NOME") then
        print("ExpNome")
        local name = eat("NOME")
        return {tag = 'ExpNome', val = name}
    elseif peek("(") then
        return parseExp()
    end
end


--[[Bloco]]
function parseBlock()
    print("parseBlock")
    local cmd = {}
    while not(peek("end") or peek("EOF") or peek("else") or peek("elseif")) do
        table.insert(cmd, parseCmd())
    end
    return cmd
end


--[[Tabela]]
function parseTabela()
    print("parseTabela")
    eat("{")
    local keyvals = {}
    local int_key = 1
    while not(peek("}")) do
        if not(peek("NOME")) then
            table.insert(keyvals, KeyVals(int_key))
            int_key = int_key + 1
        else
            table.insert(keyvals, KeyVals())
        end
    end
    eat("}")
    return {tag = "ExpTabela", keyvals = keyvals}
end


--[[KeyVals]]
function KeyVals(key)
    print("KeyVals")
    key = key or nil
    local exp = nil
    if peek("NOME") then
        local name = parseExpPrimaria()
        eat("=")
        exp = parseExp()
        return {tag = 'KeyVal', key = name, val = exp}
    else
        exp = parseExp()
        return {tag = 'KeyVal', key = key, val = exp}
    end
end


--[[Params]]
function Params()
    print("Params")
    local params = {}
    while not(peek(")")) do
        local name = parseExpSufixada()
        table.insert(params, name)
    end
    return {tag = "Params", params = params}
end


--[[Exps]]
function Exps()
    print("Exps")
    local exps = {}
    while not(peek(")")) do
        local exp = parseExp()
        table.insert(exps, exp)
    end
    return {tag = "Exps", exps = exps}
end


return parser
