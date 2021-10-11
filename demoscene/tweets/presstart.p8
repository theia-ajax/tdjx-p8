pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
cls()u=48
?"press start"
t=0memcpy(0,24576,999)b=80
::_::t+=.01cls()srand()for i=0,99 do
pset(rnd(128),(rnd(128)-t*(120+rnd(40)))%128,5)end
for i=1,8 do
pal(6,7+(i%8))v=t+i/60
for y=u,b do
sspr(0,5*(y-u)/(b-u),44,1,sin(v*2+y/100)*10+12,(y+v*100)%180-26,104,1)end
end
flip()goto _
