local lexer =  {}
-- remover aux1, aux2 do codigo...
-- resolver o problema das strings grandes e comentarios com as linhas e colunas

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
        return variable  -- string.upper(variable)
      end
  end
  return false
end


function walk(walk_col)
  --[=[
  Pass by lines and columns.
  ]=]
  local line, column = lin, col
  if walk_col then  -- sums to column
    col = col + 1
  else  -- sums to line and restart the column
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

  if c == "" then  -- eof
    return gen_token('EOF', nil, walk(true))

  elseif c == '\n' or c == '\r' then -- newline
    if (c == '\n' and string.sub(texto, pos+1, pos+1) == '\r') or
       (c == '\r' and string.sub(texto, pos+1, pos+1) == '\n') then
      pos = pos + 2
    else
      pos = pos + 1
    end
    return gen_token('NEWLINE', nil, walk(false))

  elseif c == " " or c == "\t" then -- space, tab
    pos = pos + 1
    return gen_token('SPACE', nil, walk(true))

  elseif c == "-" and string.sub(texto, pos+1, pos+1) == '-' then -- comentario
    pos = pos + 2
    if c == '[' and string.sub(texto, pos+1, pos+1) == '[' then  -- comentario bloco
      pos = pos + 1
      while true do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        if c == ']' and string.sub(texto, pos+1, pos+1) == ']' then
          pos = pos + 1
          aux1, aux2 = walk(false)
          break
        end
      end
    elseif c == '[' and string.sub(texto, pos+1, pos+1) == '=' and string.sub(texto, pos+2, pos+2) == '[' then  -- comentario bloco grande
      pos = pos + 1
      while true do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        if c == ']' and string.sub(texto, pos+1, pos+1) == '=' and string.sub(texto, pos+2, pos+2) == ']' then
          pos = pos + 1
          aux1, aux2 = walk(false)
          break
        end
      end
    else
      while true do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        if c == "\n" or c == "" or c == '\r' then
          pos = pos + 1
          aux1, aux2 = walk(false)
          break
        end
      end
    end
    aux1, aux2 = walk(true)
    return gen_token('COMMENT', nil, aux1, aux2)

  elseif string.byte(c) >= 48 and string.byte(c) <= 57 then -- numeros
    local number = c

    while true do
      pos = pos + 1
      c = string.sub(texto, pos, pos)
      if c == "" or  c == " " or c == "\t" or c == "\n" or c == '\r' then
        break
      elseif string.byte(c) < 48 or string.byte(c) > 57 then
        if c == 'x' or c == 'e' or c == '.' then
          goto continue
        elseif string.byte(c) >= 65 and string.byte(c) <= 70 then  -- hexadecimal minusculo
          goto continue
        elseif string.byte(c) >= 97 and string.byte(c) <= 102 then  -- hexadecimal maiusculo
          goto continue
        else
          break
        end
      end
      ::continue::  -- conferir com o professor se pode usar isso aqui
      number = number..c
    end
    return gen_token('NUMERO', tonumber(number), walk(true))  -- conferir se pode usar tonumber

  elseif (string.byte(c) >= 65 and string.byte(c) <= 90) or
         (string.byte(c) >= 97 and string.byte(c) <= 122) or
         c == '_' then  -- variaveis
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
      ::continue::  -- conferir com o professor se pode usar isso aqui
      variable = variable..c
    end

    is_k = is_keyword(variable)
    if is_k then  -- keyword
      return gen_token(is_k, nil, walk(true))
    else
      return gen_token('NOME', variable, walk(true))
    end

  elseif c == "'" then -- string aspas simples
    local str = ""
    while true do
      pos = pos + 1
      c = string.sub(texto, pos, pos)
      if c == "'" then
        pos = pos + 1
        break
      end
      str = str..c
    end
    return gen_token('STRING', str, walk(true))

  elseif c == '"' then -- string aspas duplas
    local str = ""
    while true do
      pos = pos + 1
      c = string.sub(texto, pos, pos)
      if c == '"' then
        pos = pos + 1
        break
      end
      str = str..c
    end
    return gen_token('STRING', str, walk(true))

  elseif c == '[' and (string.sub(texto, pos+1, pos+1) == '[' or string.sub(texto, pos+1, pos+1) == '=') then
    local str = ""
    pos = pos + 1
    c = string.sub(texto, pos, pos)
    if c == '[' then    -- string grande
      while true do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        if c == ']' and string.sub(texto, pos+1, pos+1) == ']' then
          pos = pos + 1
          break
        elseif c == "\n" or c == '\r' then
          aux1, aux2 = walk(false)
        elseif c == '\\' and (string.sub(texto, pos+1, pos+1) == 'n' or string.sub(texto, pos+1, pos+1) == 'r') then
          pos = pos + 1
          str = str..'\n'
          goto continue
        end
        str = str..c
        ::continue::  -- conferir com o professor se pode usar isso aqui
      end
    elseif c == '=' then  -- string enorme
      pos = pos + 1
      while true do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        if c == ']' and string.sub(texto, pos+1, pos+1) == '=' and string.sub(texto, pos+2, pos+2) == ']' then
          pos = pos + 2
          break
        elseif c == "\n" or c == '\r' then
          aux1, aux2 = walk(false)
        elseif c == '\\' and (string.sub(texto, pos+1, pos+1) == 'n' or string.sub(texto, pos+1, pos+1) == 'r') then
          pos = pos + 1
          str = str..'\n'
          goto continue
        end
        str = str..c
        ::continue::  -- conferir com o professor se pode usar isso aqui
      end
    end
    pos = pos + 1
    return gen_token('STRING', str, walk(true))

  elseif c == "," or c == ";" or c == ":" or c == "(" or
         c == ")" or c == "[" or c == "]" or c == "{" or c == "}" then  -- pontuacao
    pos = pos + 1
    return gen_token(c, nil, walk(true))

  elseif c == "+" or c == "-" or c == "*" or c == "/" or
         c == "^" or c == "%" or c == "#" or c == "&" or c == "|" then  -- operadores
    pos = pos + 1
    return gen_token(c, nil, walk(true))

  elseif c == "." then
    pos = pos + 1
    if string.sub(texto, pos, pos) == '.' then
      pos = pos + 1
      if string.sub(texto, pos, pos) == '.' then  -- ...
        pos = pos + 1
        return gen_token(c..string.sub(texto, pos-2, pos-1), nil, walk(true))
      else  -- ..
        return gen_token(c..string.sub(texto, pos-1, pos-1), nil, walk(true))
      end
    else
      return gen_token(c, nil, walk(true))
    end

  elseif c == "=" then
    pos = pos + 1
    if string.sub(texto, pos, pos) == '=' then  -- ==
      pos = pos + 1
      return gen_token(c..string.sub(texto, pos-1, pos-1), nil, walk(true))
    else
      return gen_token(c, nil, walk(true))
    end

  elseif c == "~" then
      pos = pos + 1
      if string.sub(texto, pos, pos) == '=' then  -- ~=
        pos = pos + 1
        return gen_token(c..string.sub(texto, pos-1, pos-1), nil, walk(true))
      else
        return gen_token(c, nil, walk(true))
      end

  elseif c == "<" then
      pos = pos + 1
      if string.sub(texto, pos, pos) == '<' or string.sub(texto, pos, pos) == '=' then  -- <= ou >>
        pos = pos + 1
        return gen_token(c..string.sub(texto, pos-1, pos-1), nil, walk(true))
      else
        return gen_token(c, nil, walk(true))
      end

  elseif c == ">" then
      pos = pos + 1
      if string.sub(texto, pos, pos) == '>' or string.sub(texto, pos, pos) == '=' then  -- <= ou <<
        pos = pos + 1
        return gen_token(c..string.sub(texto, pos-1, pos-1), nil, walk(true))
      else
        return gen_token(c, nil, walk(true))
      end

  else  -- nenhum dos casos acima
    print('\nSyntaxError at line '..tok.lin..'.'..tok.col..':\n'..
          'Character '..c.." doesn't match any token pattern.\n")
    os.exit(1)
  end

end


return lexer
