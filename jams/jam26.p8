pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
r="3d helix ★ p01"
cls()s=sin
?r
memcpy(0,0x5ff8,999)
::_::
cls()
for y=0,138 do
i=(t()*8+y/2)%114
u=y/399-t()/7
w=(27+9*s(u))*s(u)
a=abs(w/16)
for z=0,6 do
if(z*sgn(w)>5) a=11+w/9
pal(6,a+rnd())
sspr(flr(i/6)*4,i%6,3,1,64+(16+z*6)*s(u-.25)-w,y-z,w*2,1)
end
end
?r,34,50,7
flip()goto _
