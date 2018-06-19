pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
e=2.71828
::_::
cls(6)
srand()
camera(cos(t()/e*2)*32,sin(t()/(2.71828*8))*32)
for n=0,10 do
x=64y=64
r=rnd()
for i=50,1,-1 do
r=r+((t()*4+(i/e))/64)/1-n/(10*2.71828)
w=x+cos(r)*i/e
q=y+sin(r)*i/e
circ(x,y,e,7)
line(x,y,w,q,7)
x=w
y=q
end
end
flip()goto _

