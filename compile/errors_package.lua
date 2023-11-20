errors = {}

function errors.syntax_error(msg)
  --[=[
  Emite uma mensagem de syntax_error e termina a execução do programa.
  Recebe uma string contendo a mensagem de syntax_error.
  ]=]
  print('\nSyntaxError:\n', msg, '\n')
  os.exit(1)
end


return errors
