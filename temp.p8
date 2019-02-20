pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
k=128
::_::
cls()
for i=0,k*k,16+sin(t()/16) do
j=i*2/k+t()
x=i/k--+cos(j)*8
y=i%k--+sin(j)*8
r=8
c=8+(y+sin(j)*r)%7
--line(x,y,x+cos(j)*r,y+sin(j)*r,c)
circfill(x,y,4+sin(t()+i/k)*2,c)
--pset(x,y,c)
--line(x,y,x+cos(t()/2)*24,y+sin(t()/2)*24,c)
end
flip()goto _
