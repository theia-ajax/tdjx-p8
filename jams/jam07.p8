pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
::_::
cls(1)
srand()
for j=0,15 do
x=rnd(128)+t()*(128+sin(rnd())*16)
y=rnd(128)+(sin(t()/1)+1)*4+t()*(64+sin(rnd())*16)
z=rnd()*6
for i=0,64 do
pset((x-i*2)%128,(y+sin(t()*4-i/9+y/128)*(4+sin(t()+z)*z))%128,12)
end
end
flip()goto _

