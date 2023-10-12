lexer = require("lexer")
errors = require("errors_package")
local parser =  {}


function parser.init_parser(text)
    --[=[
    Inicia o parser com as variáveis 'globais'.
    Recebe uma string contendo os tokens a serem processados.
    ]=]
    lexer.init_lexer(text)
    prox = lexer.get_next_token()
end


function peek(tag)
    --[=[
    Checa se proximo token é o esperado.
    ]=]
    return prox.tag == tag
end


function eat(tag)
    --[=[
    Consome um token e avança para o próximo.
    Retorna o valor associado ao token se este existir, senão retorna sua tag identificadora.
    ]=]
    -- confere se o token possui valor associado
    if prox.value then
    current_tag = prox.value
    else
        current_tag = prox.tag
    end
    if peek(tag) then
        parser.walk()
        return current_tag
    else
        errors.syntax_error("Found: "..current_tag.." was expecting: "..prox.tag)
    end
end


function parser.walk()
    --[=[
    Avança para o próximo token.
    ]=]
    prox = lexer.get_next_token()
    -- avança os tokens que não serão utilizados na árvore
    while prox.tag == 'SPACE' or prox.tag == 'COMENTARIO' or prox.tag == 'NEWLINE' do
        prox = lexer.get_next_token()
    end
end


function get_prec(op)
    --[=[
    Retorna a precedência dado determinado operador.
    ]=]
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


--[[Prog]]
function parser.parseProg()
    local block = parseBlock()
    return {tag = 'Prog', bloco = {tag = "Bloco", block = block}}
end


--[[Cmd]]
function parseCmd()

    if peek("do") then
        eat("while")
        local block = parseBlock()
        eat("end")
        return {tag = "CmdDo", bloco = {tag = "Bloco", block = block}}

    elseif peek("while") then
        eat("while")
        local exp = parseExp()
        eat("do")
        local block = parseBlock()
        eat("end")
        return {tag = "CmdWhile", exp = exp, bloco = {tag = "Bloco", block = block}}

    elseif peek("if") then
        eat("if")
        local exp = parseExp()
        eat("then")
        local block = parseBlock()
        local elses = parseElses()
        return {tag = "CmdIfElse", exp = exp, bloco = {tag = "Bloco", block = block}, elses = elses}

    elseif peek("local") then
        eat("local")
        local name = parseExpPrimaria()
        eat("=")
        local exp = parseExp()
        return {tag = 'CmdLocal', name = name, exp = exp}

    elseif peek("function") then
        eat("function")
        local name = parseExpPrimaria()
        eat("(")
        local params = Params()
        eat(")")
        local block = parseBlock()
        eat("end")
        return {tag = "CmdFunction", name = name, params = params, bloco = {tag = "Bloco", block = block}}

    elseif peek("return") then
        eat("return")
        local exp = parseExp()
        return {tag = "CmdReturn", exp = exp}

    elseif peek("NOME") then
        local exp1 = parseExpSufixada()
        if peek("=") then
            eat("=")
            local exp2 = parseExp()
            return {tag = "CmdAtribui", name = exp1, exp = exp2}
        else
            return {tag = "CmdChamada", exp = exp1}
        end
    else
        errors.syntax_error("Found: "..prox.tag.." but was expecting a command.")
    end
end


--[[Elses]]
function parseElses()
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
            errors.syntax_error("Found: "..prox.tag.."Was expecting a elseif or else.")
        end
    end
    eat("end")
    return nil
end


--[[Exp]]
function parseExp(min_prec)
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
        local op = eat(prox.tag)
        local e2 = parseExp(min_prec + 1)
        e1 = {tag = 'ExpBin', op = op, e1 = e1, e2 = e2}
    end
    return e1
end


--[[ExpSufixada]]
function parseExpSufixada()
    local e = parseExpPrimaria()
    while true do
        if peek(".") then
            eat(".")
            e = parseExpSufixada()
            return {tag = 'ExpIndice', e = e}
        elseif peek("[") then
            eat("[")
            e = parseExp(7)
            eat("]")
            return {tag = 'ExpIndice', e = e}
        elseif peek("(") then
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
    if peek("nil") then
        eat("nil")
        return {tag = 'ExpNil', val = nil}
    elseif peek("true") or peek("false") then
        local bool = eat(prox.tag)
        return {tag = 'ExpBool', val = bool}
    elseif peek("NUMERO") then
        local number = eat('NUMERO')
        return {tag = 'ExpNum', val = number}
    elseif peek("STRING") then
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
    if peek("NOME") then
        local name = eat("NOME")
        return {tag = 'ExpNome', val = name}
    elseif peek("(") then
        return parseExp()
    end
end


--[[Bloco]]
function parseBlock()
    local cmd = {}
    while not(peek("end") or peek("EOF") or peek("else") or peek("elseif")) do
        table.insert(cmd, parseCmd())
    end
    return cmd
end


--[[Tabela]]
function parseTabela()
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
    local params = {}
    while not(peek(")")) do
        local name = parseExpSufixada()
        table.insert(params, name)
    end
    return {tag = "Params", params = params}
end


--[[Exps]]
function Exps()
    local exps = {}
    while not(peek(")")) do
        local exp = parseExp()
        table.insert(exps, exp)
    end
    return {tag = "Exps", exps = exps}
end


return parser
