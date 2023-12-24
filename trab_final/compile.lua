-- Melissa Pereira Guarilha


function init_lexer(str)
  --[=[
    Inicia o lexer com as variáveis 'globais'.
    Recebe uma string contendo os tokens a serem processados.
  ]=]
  pos = 1  -- marcador de posição
  lin, col = 1, 1  -- marcadores de linha e coluna
  texto = str  -- string a ser processada
end


function is_keyword(variable)
  --[=[
    Checa se uma variável é uma palavra reservada.
    Retorna a palavra reservada caso positivo. Do contrário, retorna falso.
  ]=]
  local i = 1
  local keywords = {'true', 'false', 'nil', 'local',
                    'while', 'for', 'do', 'end', 'in',
                    'if', 'then', 'else', 'elseif',
                    'function', 'return', 'break',
                    'repeat', 'until',
                    'not', 'and', 'or'}
  while i <= #keywords do
    if keywords[i] == variable then
      return variable
    end
    i = i + 1
  end
  return false
end


function lexer_walk(through)
  --[=[
    Avança uma coluna ou linha.
    Retorna os valores da coluna e linha salvos antes de avançar.
  ]=]
  local line, column = lin, col
  if through == 'column' then  -- soma na coluna
    col = col + 1
  elseif through == 'line' then  -- soma na linha e reinicia a coluna
    lin = lin + 1
    col = 1
  end
  return line, column
end


function gen_token(tag, value, line, column)
  --[=[
    Padroniza um token.
    Retorna uma tabela contendo a linha, coluna, tag e o respectivo valor do token, se existir.
  ]=]
  if value then
    return {lin = line, col = column, tag = tag, value = value}
  else
    return {lin = line, col = column, tag = tag}
  end
end


function get_next_token()
  --[=[
    Obtém um token.
    Retorna um token, se este for válido. 
  ]=]
  local c = string.sub(texto, pos, pos)

  --[[eof]]
  if c == "" then
    return gen_token('EOF', nil, lexer_walk('column'))

  --[[newline]]
  elseif c == '\n' or c == '\r' then
    -- condição para cobrir o caso onde a nova linha é uma dupla '\n\r'. Comum para códigos escritos em Windows.
    if string.sub(texto, pos, pos+1) == '\n\r' or string.sub(texto, pos, pos+1) == '\r\n' then
      pos = pos + 2
    else
      pos = pos + 1
    end
    return gen_token('NEWLINE', nil, lexer_walk('line'))

  --[[space, tab]]
  elseif c == " " or c == "\t" then
    pos = pos + 1
    return gen_token('SPACE', nil, lexer_walk('column'))

  --[[comentarios]]
  elseif c == "-" and string.sub(texto, pos+1, pos+1) == '-' then
    local line, column  -- marcadores de linha e coluna locais
    pos = pos + 2
    c = string.sub(texto, pos, pos)
    --[[comentario bloco]]
    if c == '[' and string.sub(texto, pos+1, pos+1) == '[' then
      pos = pos + 1
      local shouldBreak = false
      while not shouldBreak do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        -- condição de parada do comentário em bloco
        if c == ']' and string.sub(texto, pos+1, pos+1) == ']' then
          pos = pos + 2
          line, column = lexer_walk('column')
          shouldBreak = true
        -- condição de nova linha em um comentário em bloco
        elseif c == "\n" or c == '\r' then
          pos = pos + 1
          line, column = lexer_walk('line')
        end
      end
    --[[comentario bloco grande]]
    elseif c == '[' and string.sub(texto, pos+1, pos+1) == '=' and string.sub(texto, pos+2, pos+2) == '[' then
      pos = pos + 2
      local shouldBreak = false
      while not shouldBreak do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        -- condição de parada do comentário em bloco grande
        if c == ']' and string.sub(texto, pos+1, pos+1) == '=' and string.sub(texto, pos+2, pos+2) == ']' then
          pos = pos + 3
          line, column = lexer_walk('column')
          shouldBreak = true
        -- condição de nova linha em um comentário em bloco grande
        elseif c == "\n" or c == '\r' then
          pos = pos + 1
          line, column = lexer_walk('line')
        end
      end
    --[[comentario simples]]
    else
      local shouldBreak = false
      while not shouldBreak do
        -- condição de parada do comentário simples
        if c == "\n" or c == "" or c == '\r' then
          pos = pos + 1
          line, column = lexer_walk('line')
          shouldBreak = true
        end
        pos = pos + 1
        c = string.sub(texto, pos, pos)
      end
    end
    return gen_token('COMENTARIO', nil, line, column)

  --[[numeros]]  -- um token número pode se iniciar com [0-9] ou um . seguido de [0-9].
  elseif (string.byte(c) >= 48 and string.byte(c) <= 57) or
         (c == '.' and (string.byte(string.sub(texto, pos+1, pos+1)) >= 48 and string.byte(string.sub(texto, pos+1, pos+1)) <= 57)) then
    local number = c
    -- contadores para ocorrência de e+, pontos e números hexadecimais
    local count_dots, count_exp, count_x = 0, 0, 0
    local count_digits = 0  -- contador de digitos
    local should_continue = true
    while should_continue do
      count_digits = count_digits + 1
      pos = pos + 1
      c = string.sub(texto, pos, pos)
      -- condição de parada do número com uma ocorrência de nova linha
      if c == "" or  c == " " or c == "\t" or c == "\n" or c == '\r' then
        should_continue = false
      -- condição onde o token não é um número [0-9]
      elseif string.byte(c) < 48 or string.byte(c) > 57 then
        -- condição para os números decimais possuírem apenas 1 ponto
        if c == '.' and count_dots == 0 then
          count_dots = count_dots + 1
        -- condição dos números hexadecimais terem sempre a precedência '0x' e só aparecerem uma vez no número, no início.
        elseif (c == 'x' or c == 'X') and string.sub(texto, pos-1, pos-1) == '0' and count_x == 0 and count_digits == 1 then
          count_x = count_x + 1
        -- condição do expoente de 10 (e ou E) aparecer apenas uma vez no número
        elseif (c == 'e' or c == 'E') and count_exp == 0 then
          count_exp = count_exp + 1
          number = number..c
          pos = pos + 1
          c = string.sub(texto, pos, pos)
          -- condição para o token '+' aparecer apenas quando precedido de um expoente de 10
          if c == '+' then
            should_continue = true
          -- depois de um expoente de 10 é permitido qualquer número [0-9]
          elseif string.byte(c) >= 48 and string.byte(c) <= 57 then
            should_continue = true
          else
            should_continue = false
          end
        -- condição dos números hexadecimais minúsculos e maiúsculos sucederem '0x'
        elseif string.byte(c) >= 65 and string.byte(c) <= 70 and count_x == 1 then  -- minúsculo
          should_continue = true
        elseif string.byte(c) >= 97 and string.byte(c) <= 102 and count_x == 1 then -- maiúsculo
          should_continue = true
        else
          should_continue = false
        end
      end
      if should_continue then
        number = number..c
      end
    end
    return gen_token('NUMERO', tonumber(number), lexer_walk('column'))

  --[[variaveis]]  -- um token variável/nome pode se iniciar com [A-Za-z_].
  elseif (string.byte(c) >= 65 and string.byte(c) <= 90) or
         (string.byte(c) >= 97 and string.byte(c) <= 122) or
         c == '_' then
    local variable = c

    local endVariable = false
    while not endVariable do
      pos = pos + 1
      c = string.sub(texto, pos, pos)
      -- condição de parada da variável com uma ocorrência de nova linha
      if c == "" or  c == " " or c == "\t" or c == "\n" or c == '\r' then
        endVariable = true
      -- condição onde o token não é uma letra maiúscula do alfabeto [A-Z]
      elseif string.byte(c) < 65 or string.byte(c) > 90 then
        -- condição onde o token é uma letra minúscula do alfabeto [a-z] e pode estar na string
        if string.byte(c) >= 97 and string.byte(c) <= 122 then
          -- continue
        -- condição onde o token é um número [0-9] e pode estar na string
        elseif string.byte(c) >= 48 and string.byte(c) <= 57 then
          -- continue
        -- condição onde o token é um _ e pode estar na string
        elseif c == '_' then
          -- continue
        else
          endVariable = true
        end
      end
      if not endVariable then
        variable = variable..c
      end
    end

    -- checagem de variável ser ou não uma palavra reservada (keyword).
    local is_k = is_keyword(variable)
    if is_k then  -- keyword
      return gen_token(is_k, nil, lexer_walk('column'))
    else  -- variável
      return gen_token('NOME', variable, lexer_walk('column'))
    end

  --[[string aspas simples]]
  elseif c == "'" then
    local str = ""
    local endOfString = false
    while not endOfString do
      pos = pos + 1
      c = string.sub(texto, pos, pos)
      -- condição de parada da string de aspas simples
      if c == "'" then
        pos = pos + 1
        endOfString = true
      -- condição de remoção dos caracteres de escape \n e \r, com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\n' or string.sub(texto, pos, pos+1) == '\\r' then
        pos = pos + 1
        str = str..'\n'
      -- condição de remoção do caractere de escape \t, com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\t' then
        pos = pos + 1
        str = str.."\t"
      -- condição de remoção do caractere de escape \v, com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\v' then
        pos = pos + 1
        str = str.."\v"
      -- condição de remoção do caractere de escape \f, com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\f' then
        pos = pos + 1
        str = str.."\f"
      -- condição de remoção dos caracteres de escape \\ \' \", com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\\\' or string.sub(texto, pos, pos+1) == '\\\'' or
             string.sub(texto, pos, pos+1) == '\\\"' then
        pos = pos + 1
        str = str..string.sub(texto, pos, pos)
      -- condição de erro: faltando fechar as aspas simples
      elseif c == '\n' or c == '\r' or c == '' then
        print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
              'Inline literal start-string without end-string.\n')
        os.exit(1)
      -- condição de erro: escape de string inválido
      elseif c == '\\' and string.sub(texto, pos+1, pos+1) == 'w' then
        print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
              'Invalid escape character '..string.sub(texto, pos, pos+1)..'.\n')
        os.exit(1)
      else
        str = str..c
      end
    end
    return gen_token('STRING', str, lexer_walk('column'))

  --[[string aspas duplas]]
  elseif c == '"' then
    local str = ""
    local endOfString = false
    while not endOfString do
      pos = pos + 1
      c = string.sub(texto, pos, pos)
      -- condição de parada da string de aspas duplas
      if c == '"' then
        pos = pos + 1
        endOfString = true
      -- condição de remoção dos caracteres de escape \n e \r, com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\n' or string.sub(texto, pos, pos+1) == '\\r' then
        pos = pos + 1
        str = str..'\n'
      -- condição de remoção do caractere de escape \t, com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\t' then
        pos = pos + 1
        str = str.."\t"
      -- condição de remoção do caractere de escape \v, com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\v' then
        pos = pos + 1
        str = str.."\v"
      -- condição de remoção do caractere de escape \f, com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\f' then
        pos = pos + 1
        str = str.."\f"
      -- condição de remoção dos caracteres de escape \\ \' \", com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\\\' or string.sub(texto, pos, pos+1) == '\\\'' or
             string.sub(texto, pos, pos+1) == '\\\"' then
        pos = pos + 1
        str = str..string.sub(texto, pos, pos)
      -- condição de erro: faltando fechar as aspas duplas
      elseif c == '\n' or c == '\r' or c == '' then
        print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
              'Inline literal start-string without end-string.\n')
        os.exit(1)
      -- condição de erro: escape de string inválido
      elseif c == '\\' and string.sub(texto, pos+1, pos+1) == 'w' then
        print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
              'Invalid escape character '..string.sub(texto, pos, pos+1)..'.\n')
        os.exit(1)
      else
        str = str..c
      end
    end
    return gen_token('STRING', str, lexer_walk('column'))

  --[[strings especiais]]
  elseif c == '[' and (string.sub(texto, pos+1, pos+1) == '[' or string.sub(texto, pos+1, pos+1) == '=') then
    local str = ""
    local line, column  -- marcadores de linha e coluna locais

    pos = pos + 1
    c = string.sub(texto, pos, pos)
    --[[string bloco]]
    if c == '[' then
      local endOfStringBlock = false
      while not endOfStringBlock do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        -- condição de parada da string de bloco
        if c == ']' and string.sub(texto, pos+1, pos+1) == ']' then
          pos = pos + 1
          endOfStringBlock = true
        -- condição de nova linha em uma string de bloco
        elseif c == "\n" or c == '\r' then
          line, column = lexer_walk('line')
        -- condição de remoção dos caracteres de escape \n e \r, com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\n' or string.sub(texto, pos, pos+1) == '\\r' then
          pos = pos + 1
          str = str..'\n'
        -- condição de remoção do caractere de escape \t, com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\t' then
          pos = pos + 1
          str = str.."\t"
        -- condição de remoção do caractere de escape \v, com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\v' then
          pos = pos + 1
          str = str.."\v"
        -- condição de remoção do caractere de escape \f, com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\f' then
          pos = pos + 1
          str = str.."\f"
        -- condição de remoção dos caracteres de escape \\ \' \", com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\\\' or string.sub(texto, pos, pos+1) == '\\\'' or
               string.sub(texto, pos, pos+1) == '\\\"' then
          pos = pos + 1
          str = str..string.sub(texto, pos, pos)
        -- condição de erro: faltando fechar o bloco
        elseif c == '' then
          print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
                'Block start-string without end-string.\n')
          os.exit(1)
        -- condição de erro: escape de string inválido
        elseif c == '\\' and string.sub(texto, pos+1, pos+1) == 'w' then
          print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
                'Invalid escape character '..string.sub(texto, pos, pos+1)..'.\n')
          os.exit(1)
        else
          str = str..c
        end
      end
      line, column = lexer_walk('column')
    -- [[string bloco grande]]
    elseif c == '=' then
      local endOfStringBlockLarge = false
      pos = pos + 1
      while not endOfStringBlockLarge do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        -- condição de parada da string de bloco grande
        if c == ']' and string.sub(texto, pos+1, pos+1) == '=' and string.sub(texto, pos+2, pos+2) == ']' then
          pos = pos + 2
          endOfStringBlockLarge = true
        -- condição de nova linha em uma string de bloco
        elseif c == "\n" or c == '\r' then
          line, column = lexer_walk('line')
        -- condição de remoção dos caracteres de escape \n e \r, com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\n' or string.sub(texto, pos, pos+1) == '\\r' then
          pos = pos + 1
          str = str..'\n'
        -- condição de remoção do caractere de escape \t, com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\t' then
          pos = pos + 1
          str = str.."\t"
        -- condição de remoção do caractere de escape \v, com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\v' then
          pos = pos + 1
          str = str.."\v"
        -- condição de remoção do caractere de escape \f, com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\f' then
          pos = pos + 1
          str = str.."\f"
        -- condição de remoção dos caracteres de escape \\ \' \", com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\\\' or string.sub(texto, pos, pos+1) == '\\\'' or
               string.sub(texto, pos, pos+1) == '\\\"' then
          pos = pos + 1
          str = str..string.sub(texto, pos, pos)
        -- condição de erro: faltando fechar o bloco grande
        elseif c == '' then
          print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
                'Block start-string without end-string.\n')
          os.exit(1)
        -- condição de erro: escape de string inválido
        elseif c == '\\' and string.sub(texto, pos+1, pos+1) == 'w' then
          print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
                'Invalid escape character '..string.sub(texto, pos, pos+1)..'.\n')
          os.exit(1)
        else
          str = str..c
        end
      end
      line, column = lexer_walk('column')
    end
    pos = pos + 1
    return gen_token('STRING', str, line, column)

  --[[pontuacoes]]
  elseif c == "," or c == ";" or c == ":" or c == "(" or
         c == ")" or c == "[" or c == "]" or c == "{" or c == "}" then
    pos = pos + 1
    return gen_token(c, nil, lexer_walk('column'))

  --[[operadores]]
  elseif c == "+" or c == "-" or c == "*" or c == "/" or
         c == "^" or c == "%" or c == "#" or c == "&" or c == "|" then
    pos = pos + 1
    return gen_token(c, nil, lexer_walk('column'))

  --[[pontos]]
  elseif c == "." then
    pos = pos + 1
    -- condição onde há um ponto sucedendo outro ponto
    if string.sub(texto, pos, pos) == '.' then
      pos = pos + 1
      -- condição onde há três pontos seguidos
      if string.sub(texto, pos, pos) == '.' then
        pos = pos + 1
        return gen_token(c..string.sub(texto, pos-2, pos-1), nil, lexer_walk('column'))
      -- condição onde há dois pontos seguidos
      else
        return gen_token(c..string.sub(texto, pos-1, pos-1), nil, lexer_walk('column'))
      end
    -- condição onde há apenas um ponto
    else
      return gen_token(c, nil, lexer_walk('column'))
    end

  --[[iguais]]
  elseif c == "=" then
    pos = pos + 1
    -- condição onde há um token '=' sucedendo outro token '='
    if string.sub(texto, pos, pos) == '=' then
      pos = pos + 1
      return gen_token(c..string.sub(texto, pos-1, pos-1), nil, lexer_walk('column'))
    -- condição onde há apenas um token '='
    else
      return gen_token(c, nil, lexer_walk('column'))
    end

  --[[diferente e negacao]]
  elseif c == "~" then
      pos = pos + 1
      -- condição onde há um token '=' sucedendo um token '~'
      if string.sub(texto, pos, pos) == '=' then
        pos = pos + 1
        return gen_token(c..string.sub(texto, pos-1, pos-1), nil, lexer_walk('column'))
      -- condição onde há apenas um token '~'
      else
        return gen_token(c, nil, lexer_walk('column'))
      end

  --[[menor, menor ou igual e left shift]]
  elseif c == "<" then
      pos = pos + 1
      -- condição onde há um token '=' ou '<' sucedendo um token '<'
      if string.sub(texto, pos, pos) == '<' or string.sub(texto, pos, pos) == '=' then  -- <= ou <<
        pos = pos + 1
        return gen_token(c..string.sub(texto, pos-1, pos-1), nil, lexer_walk('column'))
      -- condição onde há apenas um token '<'
      else
        return gen_token(c, nil, lexer_walk('column'))
      end

  --[[maior, maior ou igual, right shift]]
  elseif c == ">" then
      pos = pos + 1
      -- condição onde há um token '=' ou '<' sucedendo um token '>'
      if string.sub(texto, pos, pos) == '>' or string.sub(texto, pos, pos) == '=' then  -- >= ou >>
        pos = pos + 1
        return gen_token(c..string.sub(texto, pos-1, pos-1), nil, lexer_walk('column'))
      -- condição onde há apenas um token '>'
      else
        return gen_token(c, nil, lexer_walk('column'))
      end

  --[[erro de token nao existente]]
  else
    print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
          'Character '..c.." doesn't match any token pattern.\n")
    os.exit(1)
  end

end


function syntax_error(msg)
    --[=[
    Emite uma mensagem de syntax_error e termina a execução do programa.
    Recebe uma string contendo a mensagem de syntax_error.
    ]=]
    print('\nSyntaxError:\n', msg, '\n')
    os.exit(1)
  end


function init_parser(text)
    --[=[
    Inicia o parser com as variáveis 'globais'.
    Recebe uma string contendo os tokens a serem processados.
    ]=]
    init_lexer(text)
    walk()
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
        walk()
        return current_tag
    else
        syntax_error("Found: "..current_tag.." was expecting: "..prox.tag)
    end
end


function walk()
    --[=[
    Avança para o próximo token.
    ]=]
    prox = get_next_token()
    -- avança os tokens que não serão utilizados na árvore
    while prox.tag == 'SPACE' or prox.tag == 'COMENTARIO' or prox.tag == 'NEWLINE' do
        prox = get_next_token()
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
function parseProg()
    local block = parseBlock()
    return {tag = 'Prog', bloco = block}
end


--[[Cmd]]
function parseCmd()

    if peek("do") then
        eat("while")
        local block = parseBlock()
        eat("end")
        return {tag = "CmdDo", bloco = block}

    elseif peek("while") then
        eat("while")
        local exp = parseExp()
        eat("do")
        local block = parseBlock()
        eat("end")
        return {tag = "CmdWhile", exp = exp, bloco = block}

    elseif peek("if") then
        eat("if")
        local exp = parseExp()
        eat("then")
        local block = parseBlock()
        local elses = parseElses()
        return {tag = "CmdIfElse", exp = exp, bloco = block, elses = elses}

    elseif peek("local") then
        eat("local")
        local name = parseExpPrimaria()
        local exp = nil
        if peek("=") then
            eat("=")
            exp = parseExp()
        end
        return {tag = 'CmdLocal', name = name, exp = exp}

    elseif peek("function") then
        eat("function")
        local name = eat("NOME")
        eat("(")
        local params = Params()
        eat(")")
        local block = parseBlock()
        eat("end")
        return {tag = "CmdFunction", name = {tag = 'ExpNome', val = name}, params = params, bloco = block}

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
        syntax_error("Found: "..prox.tag.." but was expecting a command.")
    end
end


--[[Elses]]
function parseElses()
    while not(peek("end")) do
        if peek("else") then
            eat("else")
            local block = parseBlock()
            eat("end")
            return block
        elseif peek("elseif") then
            eat("elseif")
            local exp = parseExp()
            eat("then")
            local block = parseBlock()
            local elses = parseElses()
            return {tag = "CmdIfElse", exp = exp, bloco = block, elses = elses}
        else
            syntax_error("Found: "..prox.tag.."Was expecting a elseif or else.")
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
        local e2 = parseExp(get_prec(op) + 1)
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
            local table = e
            e = parseExpSufixada()
            return {tag = 'ExpIndice', table = table,  e = e}
        elseif peek("[") then
            eat("[")
            local table = e
            e = parseExp(7)
            eat("]")
            return {tag = 'ExpIndice', table = table, e = e}
        elseif peek("(") then
            eat("(")
            local func = e
            e = Exps()
            eat(")")
            return {tag = 'ExpChamada', func = func, e = e}
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
        if bool == 'true' then bool = true else bool = false end
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
        eat("(")
        local exp = parseExp()
        eat(")")
        return exp
    end
end


--[[Bloco]]
function parseBlock()
    local cmd = {}
    while not(peek("end") or peek("EOF") or peek("else") or peek("elseif")) do
        table.insert(cmd, parseCmd())
    end
    return {tag = 'Bloco', block = cmd}
end


--[[Tabela]]
function parseTabela()
    eat("{")
    local keyvals = {}
    local int_key = 1
    while not(peek("}")) do
        if peek(",") then
            eat(",")
        end
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
        local name = {tag = 'ExpStr', val = eat("NOME")}
        eat("=")
        exp = parseExp()
        return {tag = 'KeyVal', key = name, val = exp}
    else
        exp = parseExp()
        key = {tag = 'ExpNum', val = key}
        return {tag = 'KeyVal', key = key, val = exp}
    end
end


--[[Params]]
function Params()
    local params = {}
    while not(peek(")")) do
        if peek(",") then
            eat(",")
        end
        local name = parseExpSufixada()
        table.insert(params, name)
    end
    return {tag = "Params", params = params}
end


--[[Exps]]
function Exps()
    local exps = {}
    while not(peek(")")) do
        if peek(",") then
            eat(",")
        end
        local exp = parseExp()
        table.insert(exps, exp)
    end
    return {tag = "Exps", exps = exps}
end


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
    if #e.val ~= 0 then
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
        word = word..char
        if pos == #e.val then
          loop_condition = false
        else
          pos = pos + 1
        end
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
      if string.sub(val, 1, 1) == 'l' and (instr == 'JUMP' or instr == 'JUMP_TRUE' or instr == 'JUMP_FALSE') then
        local label = labels[val].val
        print(instr..' '..label)
      else
        print(instr..' '..val)
      end
    else
      print(instr) end
    idx = idx + 1
  end
end


function main()
  texto = io.read("a")

  init_parser(texto)
  prog = parseProg()

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
