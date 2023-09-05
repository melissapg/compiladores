lexer = require("lexer")  -- modulo lexer
texto = io.read("a")
lexer.init_lexer(texto)

-- local tokens = {}  -- nao precisa, já que só vamos printar
while true do
  tok = lexer.get_next_token()
  -- table.insert(tokens, tok)  -- nao precisa, já que só vamos printar
  print(tok.tag, tok.value, tok.col, tok.lin)
  if tok.tag == 'EOF' then  -- dando erro
    break
  end
end
