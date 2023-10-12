lexer = require("lexer")  -- modulo lexer

texto = io.read("a")
lexer.init_lexer(texto)
while true do
  tok = lexer.get_next_token()
  if tok.tag ~= 'SPACE' and tok.tag ~= 'COMENTARIO' and tok.tag ~= 'NEWLINE' then
    if tok.value == nil then
      tok.value = ''
    end
    print(tok.lin..'\t'..tok.col..'\t'..tok.tag..'\t'..tok.value)
  end
  if tok.tag == 'EOF' then
    break
  end
end
