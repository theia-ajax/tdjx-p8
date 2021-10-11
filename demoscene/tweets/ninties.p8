pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
::_::
cls(8+(t()%7))
srand()
for i=0,99+sin(t())*30 do
x=(rnd(128)+t()*(16+rnd(16)))%128
y=(rnd(128)+t()*(16+rnd(16)))%128
r=10+sin(t()+rnd())*5
v=rnd()+t()/4
a=cos(v)*r+x
b=sin(v)*r+y
c=cos(v-.5)*r+x
d=sin(v-.5)*r+y
line(a,b,c,d,8+((rnd(7)+t())%7))
end
flip()goto _
