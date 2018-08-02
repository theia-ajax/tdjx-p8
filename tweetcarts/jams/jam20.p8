pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
e=2.71828
::_::
cls()
srand()
for n=2,0,-1 do
for i=min(n,5),100 do
x=cos(e*i-t()/(e*2)-n/(e*7))*(i-n)/e*3+64
y=sin(e*i-t()/(e*1)-n/(e*10))*(i-n)/e*3+64
circ(x,y,2-(i/28)+((sin(t()/2+rnd(50)/50)+1)/2*1),12-(n%2))
end
end
flip()goto _
