pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function g(n)
	return sin(cos(n*n*sin(n)+t()/20)-t()/20)
end
function f(x)
	return 64-10*g(x)
end
u=0
c=0
::_::
u=(u+1)%128
if g(u/127)>0.9 then
	cls(c*7)
	c=(c+1)%2
else
	cls(0)
end
for x=0,126 do
x2=x+1
y=f(x/127)y2=f(x2/127)
line(x,y,x2,y2,7)
end
line(u,44,u,84,8)
flip()goto _
