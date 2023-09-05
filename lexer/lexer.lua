local lexer =  {}


function lexer.init_lexer(str)
  --[=[
  Init global variables.
  ]=]
  pos = 1
  lin, col = 1, 0
  texto = str
end


function is_keyword(variable)
  --[=[
  Check if a variable is a keyword.
  ]=]
  keywords = {'true', 'false', 'nil', 'while', 'for',
              'do', 'end', 'in', 'if', 'then', 'else',
              'elseif', 'local', 'function', 'repeat',
              'until', 'return', 'break',
              'not', 'and', 'or'}  -- conferir se NOT, AND, OR são keywords ou não
  for _, v in pairs(keywords) do
      if v == variable then
        return true
      end
  end
  return false
end


function walk(dir)
  --[=[
  Pass by lines and columns.
  ]=]
  if dir == 'col' then
    col = col + 1
  else  -- sums to line and restart the column
    lin = lin + 1
    col = -1  -- mudar aqui
  end
end


function gen_token(tag, value)
  --[=[
  Generate token with accordingly tag and value, if exists.
  ]=]
  if value then
    return {lin = lin, col = col, tag = tag, value = value}
  else
    return {lin = lin, col = col, tag = tag}
  end
end


function lexer.get_next_token()
  --[=[
  Get next token from a text.
  ]=]
  local c = string.sub(texto, pos, pos)

  if c == "" then  -- eof
    return gen_token('EOF')

  elseif c == '\n' or string.byte(c) == 10 then -- newline
    pos = pos + 1
    walk()
    return gen_token('NEWLINE')

  elseif c == " " or c == "\t" then -- space, tab
    pos = pos + 1
    walk('col')
    return gen_token('SPACE')

  elseif c == "-" and string.sub(texto, pos+1, pos+1) == '-' then -- comentario
    pos = pos + 2
    if c == '[' and string.sub(texto, pos+1, pos+1) == '[' then  -- comentario bloco
      pos = pos + 1
      while true do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        if c == ']' and string.sub(texto, pos+1, pos+1) == ']' then
          pos = pos + 1
          walk()
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
          walk()
          break
        end
      end
    else
      while true do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        if c == "\n" or c == "" then
          pos = pos + 1
          walk()
          break
        end
      end
    end
    walk('col')
    return gen_token('COMMENT')

  elseif string.byte(c) >= 48 and string.byte(c) <= 57 then -- numeros
    local number = c

    while true do
      pos = pos + 1
      c = string.sub(texto, pos, pos)
      if c == "" or  c == " " or c == "\t" or c == "\n" then
        break
      elseif string.byte(c) < 48 or string.byte(c) > 57 then
        if c == 'x' or c == 'e' or c == '.' then
          goto continue
        elseif string.byte(c) >= 65 and string.byte(c) <= 70 then  -- hexadecimal
          goto continue
        else
          break
        end
      end
      ::continue::  -- conferir com o professor se pode usar isso aqui
      number = number..c
    end
    walk('col')
    return gen_token('NUMBER', number)

  elseif (string.byte(c) >= 65 and string.byte(c) <= 90) or
         (string.byte(c) >= 97 and string.byte(c) <= 122) or
         c == '_' then  -- variaveis
    local variable = c

    while true do
      pos = pos + 1
      c = string.sub(texto, pos, pos)
      if c == "" or  c == " " or c == "\t" or c == "\n" then
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

    walk('col')
    if is_keyword(variable) then  -- keyword
      return gen_token('KEYWORD', variable)
    else
      return gen_token('VARIABLE', variable)
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
    walk('col')
    return gen_token('STRING', str)

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
    walk('col')
    return gen_token('STRING', str)

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
        elseif c == "\n" then
          walk()
        end
        str = str..c
      end
    elseif c == '=' then  -- string enorme
      pos = pos + 1
      while true do
        pos = pos + 1
        c = string.sub(texto, pos, pos)
        if c == ']' and string.sub(texto, pos+1, pos+1) == '=' and string.sub(texto, pos+2, pos+2) == ']' then
          pos = pos + 2
          break
        elseif c == "\n" then
          walk()
        end
        str = str..c
      end
    end
    pos = pos + 1
    walk('col')
    return gen_token('STRING', str)

  elseif c == "," or c == ";" or c == ":" or c == "(" or
         c == ")" or c == "[" or c == "]" or c == "{" or c == "}" then  -- pontuacao
    pos = pos + 1
    walk('col')
    return gen_token(c)

  elseif c == "+" or c == "-" or c == "*" or c == "/" or
         c == "^" or c == "%" or c == "#" or c == "&" or c == "|" then  -- operadores
    pos = pos + 1
    walk('col')
    return gen_token(c)

  elseif c == "." then
    pos = pos + 1
    if string.sub(texto, pos, pos) == '.' then
      pos = pos + 1
      if string.sub(texto, pos, pos) == '.' then  -- ...
        pos = pos + 1
        walk('col')
        return gen_token(c..string.sub(texto, pos-2, pos-1))
      else  -- ..
        walk('col')
        return gen_token(c..string.sub(texto, pos-1, pos-1))
      end
    else
      walk('col')
      return gen_token(c)
    end

  elseif c == "=" then
    pos = pos + 1
    if string.sub(texto, pos, pos) == '=' then  -- ==
      pos = pos + 1
      walk('col')
      return gen_token(c..string.sub(texto, pos-1, pos-1))
    else
      walk('col')
      return gen_token(c)
    end

  elseif c == "~" then
      pos = pos + 1
      if string.sub(texto, pos, pos) == '=' then  -- ~=
        pos = pos + 1
        walk('col')
        return gen_token(c..string.sub(texto, pos-1, pos-1))
      else
        walk('col')
        return gen_token(c)
      end

  elseif c == "<" then
      pos = pos + 1
      if string.sub(texto, pos, pos) == '<' or string.sub(texto, pos, pos) == '=' then  -- <= ou >>
        pos = pos + 1
        walk('col')
        return gen_token(c..string.sub(texto, pos-1, pos-1))
      else
        walk('col')
        return gen_token(c)
      end

  elseif c == ">" then
      pos = pos + 1
      if string.sub(texto, pos, pos) == '>' or string.sub(texto, pos, pos) == '=' then  -- <= ou <<
        pos = pos + 1
        walk('col')
        return gen_token(c..string.sub(texto, pos-1, pos-1))
      else
        walk('col')
        return gen_token(c)
      end
  end

end


return lexer
