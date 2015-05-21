local shm = require('shm')
t = shm.new('test')
print('New...', t)

t:set('a', 3.14 )
print("after set: ", t)
t.a = 3.14

print(t.a)

t.b = {1, -2, -3}

if t.b then
        print("i got in here\n");
	table.foreach(t.b, print)
end
