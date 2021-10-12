pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function f(x,z,a)
return cos(a)*x-sin(a)*z,sin(a)*x+cos(a)*z+9
end
::_::
srand()
cls()
for n=0,10 do
x=cos(n/10)*4
y=n-5
z=sin(n/10)*4
a=t()/4+n*.05
b=t()/4+(n+1)*.05
c,d=f(x,z,a)
g,h=f(x,z,b)
line(64+64*c/d,64+64*y/d,64+64*g/h,64+64*y/h,7)
end
flip()goto _
