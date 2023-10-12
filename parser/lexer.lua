local lexer =  {}


function lexer.init_lexer(str)
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
  keywords = {'true', 'false', 'nil', 'local',
              'while', 'for', 'do', 'end', 'in',
              'if', 'then', 'else', 'elseif',
              'function', 'return', 'break',
              'repeat', 'until',
              'not', 'and', 'or'}
  for _, v in pairs(keywords) do
      if v == variable then
        return variable
      end
  end
  return false
end

function walk(through)
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


function lexer.get_next_token()
  --[=[
    Obtém um token.
    Retorna um token, se este for válido. 
  ]=]
  local c = string.sub(texto, pos, pos)

  --[[eof]]
  if c == "" then
    return gen_token('EOF', nil, walk('column'))

  --[[newline]]
  elseif c == '\n' or c == '\r' then
    -- condição para cobrir o caso onde a nova linha é uma dupla '\n\r'. Comum para códigos escritos em Windows.
    if string.sub(texto, pos, pos+1) == '\n\r' or string.sub(texto, pos, pos+1) == '\r\n' then
      pos = pos + 2
    else
      pos = pos + 1
    end
    return gen_token('NEWLINE', nil, walk('line'))

  --[[space, tab]]
  elseif c == " " or c == "\t" then
    pos = pos + 1
    return gen_token('SPACE', nil, walk('column'))

  --[[comentarios]]
  elseif c == "-" and string.sub(texto, pos+1, pos+1) == '-' then
    local line, column  -- marcadores de linha e coluna locais
    pos = pos + 2
    c = string.sub(texto, pos, pos)
    --[[comentario bloco]]
    if c == '[' and string.sub(texto, pos+1, pos+1) == '[' then
      pos = pos + 1
      while true do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        -- condição de parada do comentário em bloco
        if c == ']' and string.sub(texto, pos+1, pos+1) == ']' then
          pos = pos + 2
          line, column = walk('column')
          break
        -- condição de nova linha em um comentário em bloco
        elseif c == "\n" or c == '\r' then
          pos = pos + 1
          line, column = walk('line')
        end
      end
    --[[comentario bloco grande]]
    elseif c == '[' and string.sub(texto, pos+1, pos+1) == '=' and string.sub(texto, pos+2, pos+2) == '[' then
      pos = pos + 2
      while true do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        -- condição de parada do comentário em bloco grande
        if c == ']' and string.sub(texto, pos+1, pos+1) == '=' and string.sub(texto, pos+2, pos+2) == ']' then
          pos = pos + 3
          line, column = walk('column')
          break
        -- condição de nova linha em um comentário em bloco grande
        elseif c == "\n" or c == '\r' then
          pos = pos + 1
          line, column = walk('line')
        end
      end
    --[[comentario simples]]
    else
      while true do
        -- condição de parada do comentário simples
        if c == "\n" or c == "" or c == '\r' then
          pos = pos + 1
          line, column = walk('line')
          break
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

    while true do
      count_digits = count_digits + 1
      pos = pos + 1
      c = string.sub(texto, pos, pos)
      -- condição de parada do número com uma ocorrência de nova linha
      if c == "" or  c == " " or c == "\t" or c == "\n" or c == '\r' then
        break
      -- condição onde o token não é um número [0-9]
      elseif string.byte(c) < 48 or string.byte(c) > 57 then
        -- condição para os números decimais possuírem apenas 1 ponto
        if c == '.' and count_dots == 0 then
          count_dots = count_dots + 1
          goto continue
        -- condição dos números hexadecimais terem sempre a precedência '0x' e só aparecerem uma vez no número, no início.
        elseif (c == 'x' or c == 'X') and string.sub(texto, pos-1, pos-1) == '0' and count_x == 0 and count_digits == 1 then
          count_x = count_x + 1
          goto continue
        -- condição do expoente de 10 (e ou E) aparecer apenas uma vez no número
        elseif (c == 'e' or c == 'E') and count_exp == 0 then
          count_exp = count_exp + 1
          number = number..c
          pos = pos + 1
          c = string.sub(texto, pos, pos)
          -- condição para o token '+' aparecer apenas quando precedido de um expoente de 10
          if c == '+' then
            goto continue
          -- depois de um expoente de 10 é permitido qualquer número [0-9]
          elseif string.byte(c) >= 48 and string.byte(c) <= 57 then
            goto continue
          else
            break
          end
        -- condição dos números hexadecimais minúsculos e maiúsculos sucederem '0x'
        elseif string.byte(c) >= 65 and string.byte(c) <= 70 and count_x == 1 then  -- minúsculo
            goto continue
        elseif string.byte(c) >= 97 and string.byte(c) <= 102 and count_x == 1 then -- maiúsculo
          goto continue
        else
          break
        end
      end
      ::continue::
      number = number..c
    end
    return gen_token('NUMERO', tonumber(number), walk('column'))

  --[[variaveis]]  -- um token variável/nome pode se iniciar com [A-Za-z_].
  elseif (string.byte(c) >= 65 and string.byte(c) <= 90) or
         (string.byte(c) >= 97 and string.byte(c) <= 122) or
         c == '_' then
    local variable = c

    while true do
      pos = pos + 1
      c = string.sub(texto, pos, pos)
      -- condição de parada da variável com uma ocorrência de nova linha
      if c == "" or  c == " " or c == "\t" or c == "\n" or c == '\r' then
        break
      -- condição onde o token não é uma letra maiúscula do alfabeto [A-Z]
      elseif string.byte(c) < 65 or string.byte(c) > 90 then
        -- condição onde o token é uma letra minúscula do alfabeto [a-z] e pode estar na string
        if string.byte(c) >= 97 and string.byte(c) <= 122 then
          goto continue
        -- condição onde o token é um número [0-9] e pode estar na string
        elseif string.byte(c) >= 48 and string.byte(c) <= 57 then
          goto continue
        -- condição onde o token é um _ e pode estar na string
        elseif c == '_' then
          goto continue
        else
          break
        end
      end
      ::continue::
      variable = variable..c
    end

    -- checagem de variável ser ou não uma palavra reservada (keyword).
    is_k = is_keyword(variable)
    if is_k then  -- keyword
      return gen_token(is_k, nil, walk('column'))
    else  -- variável
      return gen_token('NOME', variable, walk('column'))
    end

  --[[string aspas simples]]
  elseif c == "'" then
    local str = ""
    while true do
      pos = pos + 1
      c = string.sub(texto, pos, pos)
      -- condição de parada da string de aspas simples
      if c == "'" then
        pos = pos + 1
        break
      -- condição de remoção dos caracteres de escape \n e \r, com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\n' or string.sub(texto, pos, pos+1) == '\\r' then
        pos = pos + 1
        str = str..'\n'
        goto continue
      -- condição de remoção do caractere de escape \t, com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\t' then
        pos = pos + 1
        str = str.."\t"
        goto continue
      -- condição de remoção do caractere de escape \v, com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\v' then
        pos = pos + 1
        str = str.."\v"
        goto continue
      -- condição de remoção do caractere de escape \f, com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\f' then
        pos = pos + 1
        str = str.."\f"
        goto continue
      -- condição de remoção dos caracteres de escape \\ \' \", com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\\\' or string.sub(texto, pos, pos+1) == '\\\'' or
             string.sub(texto, pos, pos+1) == '\\\"' then
        pos = pos + 1
        str = str..string.sub(texto, pos, pos)
        goto continue
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
      end
      str = str..c
      ::continue::
    end
    return gen_token('STRING', str, walk('column'))

  --[[string aspas duplas]]
  elseif c == '"' then
    local str = ""
    while true do
      pos = pos + 1
      c = string.sub(texto, pos, pos)
      -- condição de parada da string de aspas duplas
      if c == '"' then
        pos = pos + 1
        break
      -- condição de remoção dos caracteres de escape \n e \r, com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\n' or string.sub(texto, pos, pos+1) == '\\r' then
        pos = pos + 1
        str = str..'\n'
        goto continue
      -- condição de remoção do caractere de escape \t, com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\t' then
        pos = pos + 1
        str = str.."\t"
        goto continue
      -- condição de remoção do caractere de escape \v, com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\v' then
        pos = pos + 1
        str = str.."\v"
        goto continue
      -- condição de remoção do caractere de escape \f, com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\f' then
        pos = pos + 1
        str = str.."\f"
        goto continue
      -- condição de remoção dos caracteres de escape \\ \' \", com inserção direta na string
      elseif string.sub(texto, pos, pos+1) == '\\\\' or string.sub(texto, pos, pos+1) == '\\\'' or
             string.sub(texto, pos, pos+1) == '\\\"' then
        pos = pos + 1
        str = str..string.sub(texto, pos, pos)
        goto continue
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
      end
      str = str..c
      ::continue::
    end
    return gen_token('STRING', str, walk('column'))

  --[[strings especiais]]
  elseif c == '[' and (string.sub(texto, pos+1, pos+1) == '[' or string.sub(texto, pos+1, pos+1) == '=') then
    local str = ""
    local line, column  -- marcadores de linha e coluna locais

    pos = pos + 1
    c = string.sub(texto, pos, pos)
    --[[string bloco]]
    if c == '[' then
      while true do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        -- condição de parada da string de bloco
        if c == ']' and string.sub(texto, pos+1, pos+1) == ']' then
          pos = pos + 1
          break
        -- condição de nova linha em uma string de bloco
        elseif c == "\n" or c == '\r' then
          line, column = walk('line')
        -- condição de remoção dos caracteres de escape \n e \r, com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\n' or string.sub(texto, pos, pos+1) == '\\r' then
          pos = pos + 1
          str = str..'\n'
          goto continue
        -- condição de remoção do caractere de escape \t, com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\t' then
          pos = pos + 1
          str = str.."\t"
          goto continue
        -- condição de remoção do caractere de escape \v, com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\v' then
          pos = pos + 1
          str = str.."\v"
          goto continue
        -- condição de remoção do caractere de escape \f, com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\f' then
          pos = pos + 1
          str = str.."\f"
          goto continue
        -- condição de remoção dos caracteres de escape \\ \' \", com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\\\' or string.sub(texto, pos, pos+1) == '\\\'' or
               string.sub(texto, pos, pos+1) == '\\\"' then
          pos = pos + 1
          str = str..string.sub(texto, pos, pos)
          goto continue
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
        end
        str = str..c
        ::continue::
      end
      line, column = walk('column')
    -- [[string bloco grande]]
    elseif c == '=' then
      pos = pos + 1
      while true do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        -- condição de parada da string de bloco grande
        if c == ']' and string.sub(texto, pos+1, pos+1) == '=' and string.sub(texto, pos+2, pos+2) == ']' then
          pos = pos + 2
          break
        -- condição de nova linha em uma string de bloco
        elseif c == "\n" or c == '\r' then
          line, column = walk('line')
        -- condição de remoção dos caracteres de escape \n e \r, com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\n' or string.sub(texto, pos, pos+1) == '\\r' then
          pos = pos + 1
          str = str..'\n'
          goto continue
        -- condição de remoção do caractere de escape \t, com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\t' then
          pos = pos + 1
          str = str.."\t"
          goto continue
        -- condição de remoção do caractere de escape \v, com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\v' then
          pos = pos + 1
          str = str.."\v"
          goto continue
        -- condição de remoção do caractere de escape \f, com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\f' then
          pos = pos + 1
          str = str.."\f"
          goto continue
        -- condição de remoção dos caracteres de escape \\ \' \", com inserção direta na string
        elseif string.sub(texto, pos, pos+1) == '\\\\' or string.sub(texto, pos, pos+1) == '\\\'' or
               string.sub(texto, pos, pos+1) == '\\\"' then
          pos = pos + 1
          str = str..string.sub(texto, pos, pos)
          goto continue
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
        end
        str = str..c
        ::continue::
      end
      line, column = walk('column')
    end
    pos = pos + 1
    return gen_token('STRING', str, line, column)

  --[[pontuacoes]]
  elseif c == "," or c == ";" or c == ":" or c == "(" or
         c == ")" or c == "[" or c == "]" or c == "{" or c == "}" then
    pos = pos + 1
    return gen_token(c, nil, walk('column'))

  --[[operadores]]
  elseif c == "+" or c == "-" or c == "*" or c == "/" or
         c == "^" or c == "%" or c == "#" or c == "&" or c == "|" then
    pos = pos + 1
    return gen_token(c, nil, walk('column'))

  --[[pontos]]
  elseif c == "." then
    pos = pos + 1
    -- condição onde há um ponto sucedendo outro ponto
    if string.sub(texto, pos, pos) == '.' then
      pos = pos + 1
      -- condição onde há três pontos seguidos
      if string.sub(texto, pos, pos) == '.' then
        pos = pos + 1
        return gen_token(c..string.sub(texto, pos-2, pos-1), nil, walk('column'))
      -- condição onde há dois pontos seguidos
      else
        return gen_token(c..string.sub(texto, pos-1, pos-1), nil, walk('column'))
      end
    -- condição onde há apenas um ponto
    else
      return gen_token(c, nil, walk('column'))
    end

  --[[iguais]]
  elseif c == "=" then
    pos = pos + 1
    -- condição onde há um token '=' sucedendo outro token '='
    if string.sub(texto, pos, pos) == '=' then
      pos = pos + 1
      return gen_token(c..string.sub(texto, pos-1, pos-1), nil, walk('column'))
    -- condição onde há apenas um token '='
    else
      return gen_token(c, nil, walk('column'))
    end

  --[[diferente e negacao]]
  elseif c == "~" then
      pos = pos + 1
      -- condição onde há um token '=' sucedendo um token '~'
      if string.sub(texto, pos, pos) == '=' then
        pos = pos + 1
        return gen_token(c..string.sub(texto, pos-1, pos-1), nil, walk('column'))
      -- condição onde há apenas um token '~'
      else
        return gen_token(c, nil, walk('column'))
      end

  --[[menor, menor ou igual e left shift]]
  elseif c == "<" then
      pos = pos + 1
      -- condição onde há um token '=' ou '<' sucedendo um token '<'
      if string.sub(texto, pos, pos) == '<' or string.sub(texto, pos, pos) == '=' then  -- <= ou <<
        pos = pos + 1
        return gen_token(c..string.sub(texto, pos-1, pos-1), nil, walk('column'))
      -- condição onde há apenas um token '<'
      else
        return gen_token(c, nil, walk('column'))
      end

  --[[maior, maior ou igual, right shift]]
  elseif c == ">" then
      pos = pos + 1
      -- condição onde há um token '=' ou '<' sucedendo um token '>'
      if string.sub(texto, pos, pos) == '>' or string.sub(texto, pos, pos) == '=' then  -- >= ou >>
        pos = pos + 1
        return gen_token(c..string.sub(texto, pos-1, pos-1), nil, walk('column'))
      -- condição onde há apenas um token '>'
      else
        return gen_token(c, nil, walk('column'))
      end

  --[[erro de token nao existente]]
  else
    print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
          'Character '..c.." doesn't match any token pattern.\n")
    os.exit(1)
  end

end


return lexer
