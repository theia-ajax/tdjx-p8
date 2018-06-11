pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
::_::
cls(8)
srand()
for i=1,100 do
f=rnd()+t()*.1
d=rnd()*2
x=cos(f)*d-sin(f)*d
z=sin(f)*d+cos(f)*d+3
sx=64+x/z*64
sy=64+sin(rnd()+f)*2/z*64
//pset(sx,sy,7)
fillp(0xa5a5)
circfill(sx,sy,14-z,0x8f)
end
flip()goto _
