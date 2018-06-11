pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
v={1,1,1,
1,1,-1,
1,-1,1,
1,-1,-1,
-1,1,1,
-1,1,-1,
-1,-1,1,
-1,-1,-1}
i={1,2,2,3,3,4,4,5}
function x(y)
a=v[i[y]*3]
b=v[i[y]*3+1]
c=v[i[y]*3+2]
w=cos(t())*a-sin(t())*c
q=sin(t())*a+cos(t())*c+4
return 64+(64*w)/q,64+(64*b)/q
end
::_::
cls()
for j=1,#i,2 do
c,d=x(j)g,h=x(j+1)
line(c,d,g,h,7)
end
for i=1,#v,3 do
print(v[i]..","..v[i+1]..","..v[i+2],0,i*6/3)
end
flip()goto _
