pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
::_::
cls()
srand()
for i=0,399 do
a=(i/80+t()/4)%1
x=cos(a)*4-sin(a)*4
y=sin(t()/16+i/100)*4
z=sin(a)*4+cos(a)*4+10
c=10
if (a>0.3 and a<0.35) c=7
if (z>0) circfill(64+64*x/z,64+64*y/z,11-z,c)
end
flip()goto _
