pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function tx(x,y,z)return 64+(64*x)/z,64+(64*-y)/z
end
::_::
cls()
srand()
for i=1,500 do
r=rnd()x=cos(r)*rnd(4)y=sin(r)*rnd(4)z=(rnd(10)-t()*2)%10
w,q=tx(x,y,max(z,.15))d,e=tx(x,y,z+.15)
if (z<5)line(w,q,d,e,7)
end
flip()goto _
