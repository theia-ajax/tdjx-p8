pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
l=rectfill
::_::
cls()
srand(12)
l(63,64,65,69,6)
for i=0,17 do
x=rnd(8)-4+64
y=((rnd(16)+t()*30)%16)+54
pset(x,y,12)
end
for i=0,4 do
circfill(64+rnd(6)-3,54+rnd(2)-1,3,5)
end
l(0,70,127,70,11)
l(59,70,69,70,3)
for i=0,19 do
x=rnd(128)-2
l(x,64,x+2,69,8+(i%7))
end
flip()goto _
