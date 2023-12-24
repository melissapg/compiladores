-- Testes

function eu(minha, triste, vida)
  local abelha = 'a'
  abelha = 'abelha'
  local mel = 'mel'
  x = 0
  while x <= 5 do
    if x%2 == 0 then
      print("adeus "..abelha)
    else
      print(mel.."mundo cruel")
    end
    x = x+1
  end
end

function vc()
  local a_lb = 1
  local burn
  a_lb = 2
  return a_lb
end

function vc_e_eu()
  local alb = 1
  if alb > 2 then
    local lonely = 1
    alb = lonely * alb
  end
  local trinc = 4
  return alb
end


function oi(a, b)
  local c = "3"
  local d
  d = 4
  if not(c) then
    print(d..a..b..c)
  else
    print(a..b..c..d)
  end
  return a
end

function maper(list)
  i = 1
  while i <= #list do
    print(list[i])
    i = i + 1
  end
end

a = oi('1', "2")
print(a)

eu()
vc()
vc_e_eu()
print("")
print('')


function faz_nada()
  str = "panetone eh bom demais"
  print(string.byte(str))
  print(string.len(str))
  print(string.rep(str, 2, " "))
  print(string.sub(str, 1, 8))
end

faz_nada()


print("FELIZ NATAL")