pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
::_::
cls()
srand()
f=t()*24
for i=0,199 do
x=rnd(128)
y=rnd(128)
m=flr(rnd(8))+6
for n=m,1,-1 do
z=(x+f-n/4)%128
w=(y+f*4-n)%128
c=7
if(n>1)c=12
if(n/m>.6)c=1
pset(z,w,c)
pset((rnd(128)+f/10-n/4)%128,
(rnd(128)+f/10-n)%128,
1)
end
end
flip()goto _
