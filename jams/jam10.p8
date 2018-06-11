pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
f=rectfill
l=circfill
x=64y=10w=4q=0r=5g=128h=g
::_::
cls()
if(x+r>127 or x-r<0)w*=-.7
q+=0.4x+=w y+=q
if y+r>127 then
y=127-r q*=-.85g=0
else g=129 end
h=h+.2*(g-h)f(0,h,127,h+128,10)l(64,h+64,48,1)f(32,h,44,h+128,10)f(0,h+64,128,h+76,10)l(x,y,r,9)flip()goto _
