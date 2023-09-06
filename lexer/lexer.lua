local lexer =  {}


function lexer.init_lexer(str)
  --[=[
  Init global variables.
  ]=]
  pos = 1
  lin, col = 1, 1
  texto = str
end


function is_keyword(variable)
  --[=[
  Check if a variable is a keyword.
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
  Pass by lines and columns.
  ]=]
  local line, column = lin, col
  if through == 'column' then  -- sums to column
    col = col + 1
  elseif through == 'line' then  -- sums to line and restart the column
    lin = lin + 1
    col = 1
  end
  return line, column
end


function gen_token(tag, value, line, column)
  --[=[
  Generate token with accordingly tag and value, if exists.
  ]=]
  if value then
    return {lin = line, col = column, tag = tag, value = value}
  else
    return {lin = line, col = column, tag = tag}
  end
end


function lexer.get_next_token()
  --[=[
  Get next token from a text.
  ]=]
  local c = string.sub(texto, pos, pos)

  --[[eof]]
  if c == "" then
    return gen_token('EOF', nil, walk('column'))

  --[[newline]]
  elseif c == '\n' or c == '\r' then
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
    local line, column
    pos = pos + 2
    c = string.sub(texto, pos, pos)
    --[[comentario bloco]]
    if c == '[' and string.sub(texto, pos+1, pos+1) == '[' then
      pos = pos + 1
      while true do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        if c == ']' and string.sub(texto, pos+1, pos+1) == ']' then
          pos = pos + 2
          line, column = walk('column')
          break
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
        if c == ']' and string.sub(texto, pos+1, pos+1) == '=' and string.sub(texto, pos+2, pos+2) == ']' then
          pos = pos + 3
          line, column = walk('column')
          break
        elseif c == "\n" or c == '\r' then
          pos = pos + 1
          line, column = walk('line')
        end
      end
    --[[comentario simples]]
    else
      while true do
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

  -- [[numeros]]
  elseif (string.byte(c) >= 48 and string.byte(c) <= 57) or
         (c == '.' and (string.byte(string.sub(texto, pos+1, pos+1)) >= 48 and  string.byte(string.sub(texto, pos+1, pos+1)) <= 57)) then
    local number = c
    -- contadores para ocorrencia de e+, pontos e numeros hexadecimais
    local count_dots, count_exp, count_x = 0, 0, 0
    while true do
      pos = pos + 1
      c = string.sub(texto, pos, pos)
      if c == "" or  c == " " or c == "\t" or c == "\n" or c == '\r' then
        break
      elseif string.byte(c) < 48 or string.byte(c) > 57 then
        if c == '.' and count_dots == 0 then
          count_dots = count_dots + 1
          goto continue
        elseif (c == 'x' or c == 'X') and string.sub(texto, pos-1, pos-1) == '0' and count_x == 0 then
          count_x = count_x + 1
          goto continue
        elseif c == 'e' and count_exp == 0 then
          count_exp = count_exp + 1
          number = number..c
          pos = pos + 1
          c = string.sub(texto, pos, pos)
          if c == '+' then
            goto continue
          elseif string.byte(c) >= 48 and string.byte(c) <= 57 then
            goto continue
          else
            break
          end
        elseif string.byte(c) >= 65 and string.byte(c) <= 70 and count_x == 1 then  -- hexadecimal minusculo
            goto continue
        elseif string.byte(c) >= 97 and string.byte(c) <= 102 and count_x == 1 then -- hexadecimal maiusculo
          goto continue
        else
          break
        end
      end
      ::continue::
      number = number..c
    end
    return gen_token('NUMERO', tonumber(number), walk('column'))

  -- [[variaveis]]
  elseif (string.byte(c) >= 65 and string.byte(c) <= 90) or
         (string.byte(c) >= 97 and string.byte(c) <= 122) or
         c == '_' then
    local variable = c

    while true do
      pos = pos + 1
      c = string.sub(texto, pos, pos)
      if c == "" or  c == " " or c == "\t" or c == "\n" or c == '\r' then
        break
      elseif string.byte(c) < 65 or string.byte(c) > 90 then
        if string.byte(c) >= 97 and string.byte(c) <= 122 then
          goto continue
        elseif string.byte(c) >= 48 and string.byte(c) <= 57 then
          goto continue
        elseif c == '_' then
          goto continue
        else
          break
        end
      end
      ::continue::
      variable = variable..c
    end

    is_k = is_keyword(variable)
    if is_k then  -- keyword
      return gen_token(is_k, nil, walk('column'))
    else
      return gen_token('NOME', variable, walk('column'))
    end

  -- [[string aspas simples]]
  elseif c == "'" then
    local str = ""
    while true do
      pos = pos + 1
      c = string.sub(texto, pos, pos)
      if c == "'" then
        pos = pos + 1
        break
      elseif string.sub(texto, pos, pos+1) == '\\n' or string.sub(texto, pos, pos+1) == '\\r' then
        pos = pos + 1
        str = str..'\n'
        goto continue
      elseif string.sub(texto, pos, pos+1) == '\\t' then
        pos = pos + 1
        str = str.."\t"
        goto continue
      elseif string.sub(texto, pos, pos+1) == '\\v' then
        pos = pos + 1
        str = str.."\v"
        goto continue
      elseif string.sub(texto, pos, pos+1) == '\\f' then
        pos = pos + 1
        str = str.."\f"
        goto continue
      elseif string.sub(texto, pos, pos+1) == '\\\\' or string.sub(texto, pos, pos+1) == '\\\'' or
             string.sub(texto, pos, pos+1) == '\\\"' then
        pos = pos + 1
        str = str..string.sub(texto, pos, pos)
        goto continue
      elseif c == '\n' or c == '\r' or c == '' then  -- erro: faltando fecha aspas
        print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
              'Inline literal start-string without end-string.\n')
        os.exit(1)
      elseif c == '\\' and string.sub(texto, pos+1, pos+1) == 'w' then  -- erro: escape invalido
        print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
              'Invalid escape character '..string.sub(texto, pos, pos+1)..'.\n')
        os.exit(1)
      end
      str = str..c
      ::continue::
    end
    return gen_token('STRING', str, walk('column'))

  -- [[string aspas duplas]]
  elseif c == '"' then
    local str = ""
    while true do
      pos = pos + 1
      c = string.sub(texto, pos, pos)
      if c == '"' then
        pos = pos + 1
        break
      elseif string.sub(texto, pos, pos+1) == '\\n' or string.sub(texto, pos, pos+1) == '\\r' then
        pos = pos + 1
        str = str..'\n'
        goto continue
      elseif string.sub(texto, pos, pos+1) == '\\t' then
        pos = pos + 1
        str = str.."\t"
        goto continue
      elseif string.sub(texto, pos, pos+1) == '\\v' then
        pos = pos + 1
        str = str.."\v"
        goto continue
      elseif string.sub(texto, pos, pos+1) == '\\f' then
        pos = pos + 1
        str = str.."\f"
        goto continue
      elseif string.sub(texto, pos, pos+1) == '\\\\' or string.sub(texto, pos, pos+1) == '\\\'' or
             string.sub(texto, pos, pos+1) == '\\\"' then
        pos = pos + 1
        str = str..string.sub(texto, pos, pos)
        goto continue
      elseif c == '\n' or c == '\r' or c == '' then  -- erro: faltando fecha aspas
        print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
              'Inline literal start-string without end-string.\n')
        os.exit(1)
      elseif c == '\\' and string.sub(texto, pos+1, pos+1) == 'w' then  -- erro: escape invalido
        print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
              'Invalid escape character '..string.sub(texto, pos, pos+1)..'.\n')
        os.exit(1)
      end
      str = str..c
      ::continue::
    end
    return gen_token('STRING', str, walk('column'))

  -- [[strings especiais]]
  elseif c == '[' and (string.sub(texto, pos+1, pos+1) == '[' or string.sub(texto, pos+1, pos+1) == '=') then
    local str = ""
    local line, column

    pos = pos + 1
    c = string.sub(texto, pos, pos)
    -- [[string grande]]
    if c == '[' then
      while true do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        if c == ']' and string.sub(texto, pos+1, pos+1) == ']' then
          pos = pos + 1
          break
        elseif c == "\n" or c == '\r' then
          line, column = walk('line')
        elseif string.sub(texto, pos, pos+1) == '\\n' or string.sub(texto, pos, pos+1) == '\\r' then
          pos = pos + 1
          str = str..'\n'
          goto continue
        elseif string.sub(texto, pos, pos+1) == '\\t' then
          pos = pos + 1
          str = str.."\t"
          goto continue
        elseif string.sub(texto, pos, pos+1) == '\\v' then
          pos = pos + 1
          str = str.."\v"
          goto continue
        elseif string.sub(texto, pos, pos+1) == '\\f' then
          pos = pos + 1
          str = str.."\f"
          goto continue
        elseif string.sub(texto, pos, pos+1) == '\\\\' or string.sub(texto, pos, pos+1) == '\\\'' or
               string.sub(texto, pos, pos+1) == '\\\"' then
          pos = pos + 1
          str = str..string.sub(texto, pos, pos)
          goto continue
        elseif c == '' then  -- erro: faltando fecha ]]
          print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
                'Block start-string without end-string.\n')
          os.exit(1)
        elseif c == '\\' and string.sub(texto, pos+1, pos+1) == 'w' then  -- erro: escape invalido
          print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
                'Invalid escape character '..string.sub(texto, pos, pos+1)..'.\n')
          os.exit(1)
        end
        str = str..c
        ::continue::
      end
    -- [[string enorme]]
    elseif c == '=' then
      pos = pos + 1
      while true do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        if c == ']' and string.sub(texto, pos+1, pos+1) == '=' and string.sub(texto, pos+2, pos+2) == ']' then
          pos = pos + 2
          break
        elseif c == "\n" or c == '\r' then
          line, column = walk('line')
        elseif string.sub(texto, pos, pos+1) == '\\n' or string.sub(texto, pos, pos+1) == '\\r' then
          pos = pos + 1
          str = str..'\n'
          goto continue
        elseif string.sub(texto, pos, pos+1) == '\\t' then
          pos = pos + 1
          str = str.."\t"
          goto continue
        elseif string.sub(texto, pos, pos+1) == '\\v' then
          pos = pos + 1
          str = str.."\v"
          goto continue
        elseif string.sub(texto, pos, pos+1) == '\\f' then
          pos = pos + 1
          str = str.."\f"
          goto continue
        elseif string.sub(texto, pos, pos+1) == '\\\\' or string.sub(texto, pos, pos+1) == '\\\'' or
               string.sub(texto, pos, pos+1) == '\\\"' then
          pos = pos + 1
          str = str..string.sub(texto, pos, pos)
          goto continue
        elseif c == '' then  -- erro: faltando fecha ]=]
          print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
                'Block start-string without end-string.\n')
          os.exit(1)
        elseif c == '\\' and string.sub(texto, pos+1, pos+1) == 'w' then  -- erro: escape invalido
          print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
                'Invalid escape character '..string.sub(texto, pos, pos+1)..'.\n')
          os.exit(1)
        end
        str = str..c
        ::continue::
      end
    end
    pos = pos + 1
    walk('column')
    return gen_token('STRING', str, line, column)

  -- [[pontuacoes]]
  elseif c == "," or c == ";" or c == ":" or c == "(" or
         c == ")" or c == "[" or c == "]" or c == "{" or c == "}" then
    pos = pos + 1
    return gen_token(c, nil, walk('column'))

  -- [[operadores]]
  elseif c == "+" or c == "-" or c == "*" or c == "/" or
         c == "^" or c == "%" or c == "#" or c == "&" or c == "|" then
    pos = pos + 1
    return gen_token(c, nil, walk('column'))

  -- [[pontos]]
  elseif c == "." then
    pos = pos + 1
    if string.sub(texto, pos, pos) == '.' then
      pos = pos + 1
      if string.sub(texto, pos, pos) == '.' then  -- ...
        pos = pos + 1
        return gen_token(c..string.sub(texto, pos-2, pos-1), nil, walk('column'))
      else  -- ..
        return gen_token(c..string.sub(texto, pos-1, pos-1), nil, walk('column'))
      end
    else
      return gen_token(c, nil, walk('column'))
    end

  -- [[iguais]]
  elseif c == "=" then
    pos = pos + 1
    if string.sub(texto, pos, pos) == '=' then  -- ==
      pos = pos + 1
      return gen_token(c..string.sub(texto, pos-1, pos-1), nil, walk('column'))
    else
      return gen_token(c, nil, walk('column'))
    end

  -- [[diferente e negacao]]
  elseif c == "~" then
      pos = pos + 1
      if string.sub(texto, pos, pos) == '=' then  -- ~=
        pos = pos + 1
        return gen_token(c..string.sub(texto, pos-1, pos-1), nil, walk('column'))
      else
        return gen_token(c, nil, walk('column'))
      end

  -- [[menor, menor ou igual e left shift]]
  elseif c == "<" then
      pos = pos + 1
      if string.sub(texto, pos, pos) == '<' or string.sub(texto, pos, pos) == '=' then  -- <= ou <<
        pos = pos + 1
        return gen_token(c..string.sub(texto, pos-1, pos-1), nil, walk('column'))
      else
        return gen_token(c, nil, walk('column'))
      end

  -- [[maior, maior ou igual, right shift]]
  elseif c == ">" then
      pos = pos + 1
      if string.sub(texto, pos, pos) == '>' or string.sub(texto, pos, pos) == '=' then  -- >= ou >>
        pos = pos + 1
        return gen_token(c..string.sub(texto, pos-1, pos-1), nil, walk('column'))
      else
        return gen_token(c, nil, walk('column'))
      end

  -- [[erro de token nao existente]]
  else  -- nenhum dos casos acima
    print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
          'Character '..c.." doesn't match any token pattern.\n")
    os.exit(1)
  end

end


return lexer
