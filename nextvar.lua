print('testando tables, next e fors')

if T then
-- testes de tamanhos

function mp2 (n)   -- minimum power of 2 >= n
  return 2^ceil(log(n)/log(2))
end
  
function check (t, na, nh, p)
  if nh < 2 then nh = 2 end   -- tamanho minimo de hash
  local a, h = T.querytab(t)
  if p then print(na, nh, a, h) end
  assert(a == na and (nh == -1 or h == nh))
end

-- teste de tamanho de construtores
local lim = 20
local s = 'return {'
for i=1,lim do
  s = s..i..','
  local s = s..';'
  for k=0,lim do 
    check(dostring(s..'}'), mp2(i), mp2(k+1))
    s = format('%sa%d=%d,', s, k, k)
  end
end
check({}, 0, 2)

print'+'

-- teste de tamanho com construcao dinamica
for i = 4,100 do
  local a = {}
  local p = mp2(i-1)     -- -1 because 1 always may be in hash part
  for j=1,i do a[j] = 1 end
  check(a, p, 2)
end

local a = {}
for i=1,16 do a[i] = i end
check(a, 16, 2)
for i=1,10 do a[i] = nil end
for i=30,40 do a[i] = nil end   -- force a rehash
check(a, 0, 8)
a[1] = 1
for i=30,40 do a[i] = nil end   -- force a rehash
check(a, 0, 16)
for i=1,13 do a[i] = nil end
for i=30,50 do a[i] = nil end   -- force a rehash
check(a, 0, 4)
for i=1,20 do a[i] = nil end   -- force a rehash
check(a, 0, 2)
for i=1,2 do a[i] = 1 end
check(a, 2, 2)

-- reverse filling
for i=10,200 do
  local a = {}
  for i=i,1,-1 do a[i] = i end   -- fill in reverse
  check(a, mp2(i), 2)
end

end

print'+'



nofind = {}

a,b,c = 1,2,3
a,b,c = nil

function find (name)
  local n,v
  local _G = globals()
  while 1 do
    n,v = next(_G, n)
    if not n then return nofind end
    assert(v ~= nil)
    if n == name then return v end
  end
end

function find1 (name)
  for n,v in globals() do
    if n==name then return v end
  end
  return nil  -- not found
end

do   -- create 10000 new global variables
  for i=1,10000 do
    setglobal(i, i)
  end
end


-- check deprecated functions
if not (nextvar and call(nextvar, {n=1}, "x", nil)) then
  print("obsolete functions not active")
else

  local _G = globals()
  do
    local a,v
    while 1 do
      a,v = nextvar(a)
      if not a then break end
      assert(v and v == getglobal(a))
    end
  end

  foreachvar(function (n, v)
               assert(v and getglobal(n) == v)
             end)

  rawsetglobal('a', 'alo')
  assert(_G.a == 'alo' and rawgetglobal('a') == _G.a)

  a = {10,20}
  rawsettable(a, 1, 100)
  assert(a[1] == 100 and rawgettable(a, 2) == 20)

end

a = {x=90, y=8, z=23}
assert(foreach(a, function(i,v) if i=='x' then return v end end) == 90)
assert(foreach(a, function(i,v) if i=='a' then return v end end) == nil)
foreach({}, error)

foreachi({x=10, y=20}, error)
local a = {n = 1}
foreachi({n=3}, function (i, v) assert(%a.n == i and not v); %a.n=%a.n+1 end)
a = {10,20,30,nil,50}
foreachi(a, function (i,v) assert(a[i] == v) end)
assert(foreachi({'a', 'b', 'c'}, function (i,v)
         if i==2 then return v end
       end) == 'b')


assert(print==find("print") and print == find1("print"))
assert(getglobal("print")==find("print"))
assert(assert==find1("assert"))
assert(nofind==find("return"))
assert(not find1("return"))
setglobal("ret" .. "urn", nil)
assert(nofind==find("return"))
setglobal("xxx", 1)
assert(getglobal("xxx", 1) == 1)
assert(xxx==find("xxx"))
print('+')

a = {}
for i=0,10000 do
  if mod(i,10) ~= 0 then
    a['x'..i] = i
  end
end

n = {n=0}
for i,v in a do
  n.n = n.n+1
  assert(i and v and a[i] == v)
end
assert(n.n == 9000)
a = nil

do   -- remove those 10000 new global variables
  for i=1,10000 do
    setglobal(i, nil)
  end
end

do
  local a = {}
  for n,v in globals() do a[n]=v end
  for n,v in a do
    if type(v) ~= type(print) and not strfind(n, "^[%u_]") then
      setglobal(n, nil);
    end
    collectgarbage()
  end
end

do
  local globals, assert, next = globals, assert, next
  local n = {gl1=3}
  local a = globals(n)
  assert(print == nil and gl1 == 3)
  gl1 = nil
  gl = 1
  assert(n.gl == 1 and next(n, 'gl') == nil)
  globals(a)

  print'+'
end

function checknext (a)
  local b = {}
  foreach(a, function (k,v) b[k] = v end)
  for k,v in b do assert(a[k] == v) end
  for k,v in a do assert(b[k] == v) end
  b = {}
  do local k,v = next(a); while k do b[k] = v; k,v = next(a,k) end end
  for k,v in b do assert(a[k] == v) end
  for k,v in a do assert(b[k] == v) end
end

checknext{1;x=1,y=2,z=3}
checknext{1,2;x=1,y=2,z=3}
checknext{1,2,3;x=1,y=2,z=3}
checknext{1,2,3,4;x=1,y=2,z=3}
checknext{1,2,3,4,5;x=1,y=2,z=3}

assert(getn{n=20} == 20)
assert(getn{1,2,3; n=1} == 1)
assert(getn{[-1] = 2} == 0)
assert(getn{1,2,3,nil,5} == 5)

print("+")

a = {n=0, [6] = "ban"}
tinsert(a, 10); tinsert(a, 2, 20); tinsert(a, 1, -1); tinsert(a, 40);
tinsert(a, a.n+1, 50)
assert(tremove(a,1) == -1)
assert(tremove(a,1) == 10)
assert(tremove(a,1) == 20)
assert(tremove(a,1) == 40)
assert(tremove(a,1) == 50)
assert(tremove(a,1) == nil)
assert(a.n == 0 and a[6] == "ban")
tinsert(a, 1, 10); tinsert(a, 1, 20); tinsert(a, 1, -1)
assert(tremove(a) == 10)
assert(tremove(a) == 20)
assert(tremove(a) == -1)

a = {}
tinsert(a, 3, 'a')
tinsert(a, 'b')
assert(tremove(a, 1) == nil)
assert(tremove(a, 1) == nil)
assert(tremove(a, 1) == 'a')
assert(tremove(a, 1) == 'b')
assert(getn(a) == 0)
print("+")

a = {}
for i=1,1000 do
  a[i] = i; a[i-1] = nil
end
assert(next(a,nil) == 1000 and next(a,1000) == nil)

assert(next({}) == nil)
assert(next({}, nil) == nil)

for a,b in {} do error"not here" end
for i=1,0 do error'not here' end
for i=0,1,-1 do error'not here' end
a = nil; for i=1,1 do assert(not a); a=1 end; assert(a)
a = nil; for i=1,1,-1 do assert(not a); a=1 end; assert(a)

a = 0; for i=0, 1, 0.1 do a=a+1 end; assert(a==11)
-- precision problems
--a = 0; for i=1, 0, -0.01 do a=a+1 end; assert(a==101)
a = 0; for i=0, 0.999999999, 0.1 do a=a+1 end; assert(a==10)
a = 0; for i=1, 1, 1 do a=a+1 end; assert(a==1)
a = 0; for i=1e10, 1e10, -1 do a=a+1 end; assert(a==1)
a = 0; for i=1, 0.99999, 1 do a=a+1 end; assert(a==0)
a = 0; for i=99999, 1e5, -1 do a=a+1 end; assert(a==0)
a = 0; for i=1, 0.99999, -1 do a=a+1 end; assert(a==1)

-- conversion
a = 0; for i="10","1","-2" do a=a+1 end; assert(a==5)


collectgarbage()

print"OK"
