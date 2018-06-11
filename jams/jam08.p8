pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
_set_fps(60)
::_::
cls(1)
srand()
for j=0,11 do
f=t()/2
x=rnd(128)+f*(128+sin(rnd())*16)
y=rnd(128)+(sin(f/2)+1)*4+f*(64+sin(rnd())*16)
z=rnd()*6
for i=0,64 do
pset((x-i*2)%128,(y+sin(f*.1-i/32+y/128)*(12+sin(f/2+z)*z*2))%128,12)
end
end
flip()goto _
