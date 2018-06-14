pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
f=circfill
::_::
cls(1)
srand()
for n=0,14 do
x=64y=120r=.25z=x
w=y
for d=0,20 do
s=.1+(sin(t()/8)/40-1/80)
r+=rnd()*s-(s/2)+sin(t()/4)/800
z=x
w=y
x+=5*cos(r)y+=5*sin(r)f(x,y,5,0x28)u=cos(r+.25)v=sin(r+.25)line(z+u*5,w+v*5,x+u*5,y+v*5,14)end
end
flip()goto _
